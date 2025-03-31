import pandas as pd
import os
import re
from datetime import datetime

class OtimizadorIFQ6:
    def validacao(self, paths):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01", "CD_02", "CD_03"
        ]
        
        lista_df = []
        equipes_utilizadas = {}  # Para controle dos sufixos (_2, _3, etc.)
        processed_files = []     # Armazena tuplas (caminho_final, equipe_final) de arquivos processados

        # O diretório base é obtido a partir do primeiro path informado
        base_dir = os.path.dirname(paths[0])
        
        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]

        # Se já estivermos na pasta do mês (ex: "Março"), use-a; senão, construa o caminho
        if os.path.basename(os.path.normpath(base_dir)).upper() == nome_mes.upper():
            pasta_mes = base_dir
        else:
            pasta_mes = os.path.join(os.path.dirname(base_dir), nome_mes)

        pasta_output = os.path.join(pasta_mes, 'output')
        pasta_dados = os.path.join(pasta_mes, 'dados')
        
        os.makedirs(pasta_mes, exist_ok=True)
        os.makedirs(pasta_output, exist_ok=True)
        os.makedirs(pasta_dados, exist_ok=True)
        
        for path in paths:
            if not os.path.exists(path):
                print(f"Arquivo '{path}' não encontrado.")
                # Se não encontrar, sobe uma pasta e tenta em: <pasta_pai>/<nome_mes>/dados/<nome_arquivo>
                while True:
                    eqp = input("Selecione a equipe para localizar a pasta deste arquivo (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ")
                    if eqp in [1, 2, 3]:
                        break
                    print("Escolha inválida. Digite 1, 2 ou 3.")
                if eqp == 1:
                    nome_equipe = "LEBATEC"
                elif eqp == 2:
                    nome_equipe = "BRAVORE"
                else:
                    nome_equipe = "PROPRIA"
                
                fallback_base = os.path.dirname(base_dir)
                fallback_path = os.path.join(fallback_base, nome_mes, 'dados', nome_equipe,os.path.basename(path))
                print(f"Verificando no caminho de fallback: {fallback_path}")
                if not os.path.exists(fallback_path):
                    print(f"Erro: O arquivo '{fallback_path}' também não foi encontrado.")
                    continue
                else:
                    print(f"Arquivo encontrado no caminho de fallback: {fallback_path}")
                    path = fallback_path

            print(f"Processando o arquivo: {path}")
            df = pd.read_excel(path)
            df.columns = [col.upper() for col in df.columns]

            colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
            if colunas_faltando:
                print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
                continue

            df_filtrado = df[nomes_colunas].copy()
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_filtrado['check dup'] = df_filtrado.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

            df_filtrado['CHAVE_DUPLICADA'] = df_filtrado[dup_columns].astype(str).agg('-'.join, axis=1)
            df_filtrado['CHAVE_DUPLICADA'] = df_filtrado.apply(
                lambda row: row['CHAVE_DUPLICADA'] if row['check dup'] == 'VERIFICAR' else '',
                axis=1
            )
            if 'VERIFICAR' not in df_filtrado['check dup'].values:
                df_filtrado['grupo'] = (df_filtrado['NM_FILA'] != df_filtrado['NM_FILA'].shift()).cumsum()
                df_filtrado['NM_COVA'] = df_filtrado.groupby('grupo').cumcount() + 1
                df_filtrado.drop(columns=['grupo'], inplace=True)
                for idx in range(1, len(df_filtrado)):
                    atual = df_filtrado.iloc[idx]
                    anterior = df_filtrado.iloc[idx - 1]
                    if atual['NM_FILA'] == anterior['NM_FILA']:
                        if atual['CD_01'] == 'L':
                            df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA']
                        else:
                            continue

            df_filtrado["CD_TALHAO"] = df_filtrado["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

            filename = os.path.basename(path)
            print(f"\nArquivo: {filename}")
            while True:
                escolha = input("Selecione a equipe para este arquivo (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ").strip()
                if escolha in ['1', '2', '3']:
                    break
                print("Escolha inválida. Digite 1, 2 ou 3.")

            if escolha == '1':
                equipe_base = "LEBATEC"
            elif escolha == '2':
                equipe_base = "BRAVORE"
            else:
                equipe_base = "PROPRIA"

            if equipe_base in equipes_utilizadas:
                equipes_utilizadas[equipe_base] += 1
                equipe_final = f"{equipe_base}_{equipes_utilizadas[equipe_base]}"
            else:
                equipes_utilizadas[equipe_base] = 1
                equipe_final = equipe_base

            print(f"Equipe identificada: {equipe_final}")
            df_filtrado['EQUIPES'] = equipe_final

            valid_letters = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W')
            df_filtrado['check cd'] = df_filtrado.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK'),
                axis=1
            )
            lista_df.append(df_filtrado)
            processed_files.append((path, equipe_final))

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)
            novo_arquivo_excel = os.path.join(pasta_output, f'IFQ6_dados_{nome_mes}_EPS02.xlsx')
            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
        else:
            print("Nenhum arquivo foi processado com sucesso.")

        for file_path, equipe_final in processed_files:
            pasta_equipe = os.path.join(pasta_dados, equipe_final.split('_')[0])
            os.makedirs(pasta_equipe, exist_ok=True)
            nome_arquivo = os.path.basename(file_path)
            destino = os.path.join(pasta_equipe, nome_arquivo)
            if os.path.exists(file_path):
                try:
                    os.rename(file_path, destino)
                    print(f"Arquivo '{nome_arquivo}' movido para '{pasta_equipe}'.")
                except Exception as e:
                    print(f"Erro ao mover '{nome_arquivo}' para '{pasta_equipe}': {e}")

# Exemplo de uso
otimizador = OtimizadorIFQ6()

arquivos = [
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6271_TABOCA_SRP - IFQ6 (4).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6348_BERRANTE_II_RRP - IFQ6 (29).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx",
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\05- Inventário Florestal Qualitativo\Teste IFQ6\IFQ6_dados_teste_EPS02\6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx",
]

otimizador.validacao(arquivos)
