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
        equipe_contador = {}

        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]

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

            equipe_contador[nome_equipe] = equipe_contador.get(nome_equipe, 0) + 1
            nome_equipe_incrementado = f"{nome_equipe}_{str(equipe_contador[nome_equipe]).zfill(2)}"

            df = pd.read_excel(path, sheet_name=0)
            df.columns = [str(col).strip().upper() for col in df.columns]

            colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
            if colunas_faltando:
                print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
                continue

            df_filtrado = df[nomes_colunas].copy()
            df_filtrado['EQUIPE'] = nome_equipe_incrementado
            lista_df.append(df_filtrado)

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)

            for col in ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']:
                df_final[col] = df_final[col].astype(str).str.strip().str.upper()

            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_final['check dup'] = df_final.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

            if 'VERIFICAR' not in df_final['check dup'].values:
                df_final['grupo'] = (df_final['NM_FILA'] != df_final['NM_FILA'].shift()).cumsum()
                df_final['NM_COVA'] = df_final.groupby('grupo').cumcount() + 1
                df_final.drop(columns=['grupo'], inplace=True)

            df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

            equipes_juntadas = sorted(set(df_final['EQUIPE'].unique()))
            nome_base = "_".join(nome_equipe)
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
    "/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx",
    "/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx",
    "/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx",
    "/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx",
    "/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx",
    "/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx",
    "/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx",
    "/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx",
    "/6271_TABOCA_SRP - IFQ6 (4).xlsx"
]

otimizador.validacao(arquivos)

#COISAS FALTANDO NO CODIGO:

#1)NM_COVA tem que ser com base no NM_FILA por exemplo:
#nm_fila tem 1,1,1,1 entao nm_cova sera igual a 1,2,3,4 ai outro nm_fila será 2,2,2 entao nm_cova sera 1,2,3 e assim sucessivamente.
#2)verificação do L se tem fuste == 1 e se tiver lançar verificar em 'check cd_01' se nao lançar um 'ok'.
#3)tratar de arrumar o nome nao deveria ser o nome de todos os arquivos juntos e sim somente a equipe que o usuario escolher e tem que ter como base o nome "IFQ6_{nome do mes}_{nome da equipe que foi selecionada}_{e a data de emissao do arquivo}"
#4)a logica dos nomes deve continuar se tiver mais de uma equipe fica IFQ6_{nome da equipe primaria} e {nome da equipe segundaria}_{data de emissao} e se for todas equipes "IFQ6_{nome do mes}_{data de emissão}"
#5)os outros parametros devem ser os mesmos oque deve ser mudado é oque está aqui.
