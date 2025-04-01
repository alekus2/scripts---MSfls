import pandas as pd
import os
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
        processed_files = []

        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]

        base_path = os.path.abspath(paths[0])
        if nome_mes.lower() in base_path.lower():
            parent_dir = os.path.dirname(base_path)
            if os.path.basename(parent_dir).lower() == 'output':
                pasta_output = parent_dir
            else:
                pasta_output = os.path.join(parent_dir, 'output')
                os.makedirs(pasta_output, exist_ok=True)
        else:
            base_dir = os.path.dirname(paths[0])
            pasta_mes = os.path.join(os.path.dirname(base_dir), nome_mes)
            pasta_output = os.path.join(pasta_mes, 'output')
            os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue

            nome_arquivo = os.path.basename(path).upper()
            if 'LEBATEC' in nome_arquivo:
                nome_equipe = "LEBATEC"
            elif 'BRAVORE' in nome_arquivo:
                nome_equipe = "BRAVORE"
            elif 'PROPRIA' in nome_arquivo:
                nome_equipe = "PROPRIA"
            else:
                while True:
                    eqp = input("Selecione a equipe (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ")
                    if eqp in ['1', '2', '3']:
                        break
                nome_equipe = ["LEBATEC", "BRAVORE", "PROPRIA"][int(eqp) - 1]

            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=0)
            df.columns = [str(col).strip().upper() for col in df.columns]

            colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
            if colunas_faltando:
                print(f"Colunas da planilha: {df.columns}")
                print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
                print("Vamos verificar na segunda aba...")
                try:
                    df = pd.read_excel(path, sheet_name=1)
                    df.columns = [str(col).strip().upper() for col in df.columns]
                    colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
                    if colunas_faltando:
                        print(f"Erro: As colunas esperadas não foram encontradas na segunda aba do arquivo '{path}': {', '.join(colunas_faltando)}")
                        continue
                    else:
                        print("Tudo certo, processando...")
                except Exception as e:
                    print(f"Erro ao ler a segunda aba do arquivo '{path}': {e}")
                    continue  

            df_filtrado = df[nomes_colunas].copy()
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_filtrado['check dup'] = df_filtrado.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

            df_filtrado['CHAVE_DUPLICADA'] = df_filtrado[dup_columns].astype(str).agg('-'.join, axis=1)
            df_filtrado['CHAVE_DUPLICADA'] = df_filtrado.apply(
                lambda row: row['CHAVE_DUPLICADA'] if row['check dup'] == 'VERIFICAR' else '',
                axis=1
            )

            df_filtrado['check cd_01'] = df_filtrado.apply(
                lambda row: 'VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK',
                axis=1
            )
            if 'VERIFICAR' not in df_filtrado['check dup'].values:
                df_filtrado['grupo'] = (df_filtrado['NM_FILA'] != df_filtrado['NM_FILA'].shift()).cumsum()
                df_filtrado['NM_COVA'] = df_filtrado.groupby('grupo').cumcount() + 1
                df_filtrado.drop(columns=['grupo'], inplace=True)

            df_filtrado["CD_TALHAO"] = df_filtrado["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)
            df_filtrado['EQUIPE'] = nome_equipe

            lista_df.append(df_filtrado)
            processed_files.append((path, nome_equipe))

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)
            equipes_juntadas = sorted(set(equipe for _, equipe in processed_files))

            if len(equipes_juntadas) == 1:
                nome_base = f"dados_{equipes_juntadas[0].lower()}"
            elif len(equipes_juntadas) == 2:
                nome_base = f"dados_{equipes_juntadas[0].lower()}_{equipes_juntadas[1].lower()}"
            else:
                nome_base = "dados_geral_juncao"

            contador = 1
            novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            while os.path.exists(novo_arquivo_excel):
                contador += 1
                novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")

            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
        else:
            print("Nenhum arquivo foi processado com sucesso.")

# Exemplo de uso
otimizador = OtimizadorIFQ6()

arquivos = [
    "/Abril/output/dados_bravore_01.xlsx",
    "/Abril/output/dados_lebatec_01.xlsx",
    "/Abril/output/dados_propria_01.xlsx"
]

otimizador.validacao(arquivos)
