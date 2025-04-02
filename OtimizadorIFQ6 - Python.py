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
        equipes = {}

        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]
        data_emissao = datetime.now().strftime("%Y%m%d")

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
                nome_equipe_base = "lebatec"
            elif 'BRAVORE' in nome_arquivo:
                nome_equipe_base = "bravore"
            elif 'PROPRIA' in nome_arquivo:
                nome_equipe_base = "propria"
            else:
                while True:
                    eqp = input("Selecione a equipe (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ")
                    if eqp in ['1', '2', '3']:
                        break
                nome_equipe_base = ["lebatec", "bravore", "propria"][int(eqp) - 1]

            equipes[nome_equipe_base] = equipes.get(nome_equipe_base, 0) + 1
            nome_equipe = nome_equipe_base if equipes[nome_equipe_base] == 1 else f"{nome_equipe_base}_{equipes[nome_equipe_base]:02d}"

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
            df_filtrado['EQUIPE'] = nome_equipe
            lista_df.append(df_filtrado)

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)

            for col in ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']:
                df_final[col] = df_final[col].astype(str).str.strip().str.upper()

            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_final['check dup'] = df_final.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

            valid_letters = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W')
            df_final['check cd'] = df_filtrado.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK'),
                axis=1
            )

            df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

            df_final['grupo'] = (df_final['NM_FILA'] != df_final['NM_FILA'].shift()).cumsum()
            df_final['NM_COVA'] = df_final.groupby('grupo').cumcount() + 1
            df_final.drop(columns=['grupo'], inplace=True)
            for idx in range(1, len(df_final)):
                    atual = df_final.iloc[idx]
                    anterior = df_final.iloc[idx - 1]
                    if atual['NM_FILA'] == anterior['NM_FILA']:
                        if atual['CD_01'] == 'L':
                            df_final.at[idx, 'NM_COVA'] = df_final.at[idx - 1, 'NM_COVA']
                        else:
                            continue
            
            df_final['check SQC'] = df_final.apply(lambda row: 'OK' if atual['NM_COVA'] == anterior['NM_COVA'] and anterior['CD_01'] == 'N' else ('VERIFICAR' if anterior['CD_01'] == 'L' and atual['CD_01'] == 'N'), axis=1)
            
            if len(equipes) == 1:
                nome_base = f"IFQ6_{nome_mes}_{list(equipes.keys())[0]}_{data_emissao}"
            elif len(equipes) == 2:
                nome_base = f"IFQ6_{list(equipes.keys())[0]}_e_{list(equipes.keys())[1]}_{data_emissao}"
            else:
                nome_base = f"IFQ6_{nome_mes}_{data_emissao}"

            contador = 1
            novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            while os.path.exists(novo_arquivo_excel):
                contador += 1
                novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")

            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"✅ Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
        else:
            print("❌ Nenhum arquivo foi processado com sucesso.")
          
# Exemplo de uso
otimizador = OtimizadorIFQ6()

arquivos = [
        "/content/IFQ6_MS_Florestal_Bravore_10032025.xlsx",
        "/content/IFQ6_MS_Florestal_Bravore_17032025.xlsx",
        "/content/IFQ6_MS_Florestal_Bravore_24032025.xlsx"
        ]

otimizador.validacao(arquivos)
