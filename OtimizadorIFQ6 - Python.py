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
        equipes_utilizadas = {}
        
        base_dir = os.path.dirname(paths[0])
        
        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]
        
        for path in paths:
            if not os.path.exists(path):
                print(f"Arquivo '{path}' não encontrado. Verificando na pasta 'dados'.")
                dados_path = os.path.join(base_dir, nome_mes, 'dados', os.path.basename(path))
                if not os.path.exists(dados_path):
                    print(f"Erro: O arquivo '{dados_path}' também não foi encontrado.")
                    continue
                else:
                    print(f"Arquivo encontrado na pasta 'dados': {dados_path}")
                    path = dados_path

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

            filename = os.path.basename(path).upper() 
            equipes_possiveis = ['BRAVORE', 'LEBATEC', 'PROPRIA']
            equipe = next((equipe for equipe in equipes_possiveis if equipe in filename), None)

            if equipe is None:
                equipe = input("Nenhum time válido encontrado no nome do arquivo. Por favor, insira o nome da equipe: ")
            
            if equipe in equipes_utilizadas:
                equipes_utilizadas[equipe] += 1
                equipe_final = f"{equipe}_{equipes_utilizadas[equipe]}"
            else:
                equipes_utilizadas[equipe] = 1
                equipe_final = equipe
            
            print(f"Equipe identificada: {equipe_final}")
            df_filtrado['EQUIPES'] = equipe_final

            valid_letters = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W')

            df_filtrado['check cd'] = df_filtrado.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK'),
                axis=1
            )
            lista_df.append(df_filtrado)

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)

            pasta_mes = os.path.join(base_dir, nome_mes)
            pasta_output = os.path.join(pasta_mes, 'output')
            pasta_dados = os.path.join(pasta_mes, 'dados')

            if not os.path.exists(pasta_mes):
                os.makedirs(pasta_mes)
            
            os.makedirs(pasta_output, exist_ok=True)
            os.makedirs(pasta_dados, exist_ok=True)

            for path in paths:
                nome_arquivo = os.path.basename(path)
                destino = os.path.join(pasta_dados, nome_arquivo)
                if os.path.exists(path):  
                    os.rename(path, destino)

            novo_arquivo_excel = os.path.join(pasta_output, f'IFQ6_dados_{nome_mes}_EPS02.xlsx')
            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
        else:
            print("Nenhum arquivo foi processado com sucesso.")

# Exemplo de uso
otimizador = OtimizadorIFQ6()
arquivos = [
    '/content/Março/dados/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx',
    '/content/Março/dados/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx',
    '/content/Março/dados/6271_TABOCA_SRP - IFQ6 (4).xlsx',
    '/content/Março/dados/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx',
    '/content/Março/dados/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx',
    '/content/Março/dados/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx',
    '/content/Março/dados/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx',
    '/content/Março/dados/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsxlel'
]
otimizador.validacao(arquivos)s
