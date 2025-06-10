from pickle import TRUE
import pandas as pd
import os
from datetime import datetime

class farming:
    def trans_colunas(self, paths):
        nomes_colunas_trans = ["INDEX_2","MONTHS","MONTH/YEAR MEASUREMENT","PLANTED DATE","MEASURING DATE","AGE(DAYS)",
                               "GM","FARM","INDEX","GENETIC MATERIAL","ÁREA(HA)","Survival(%)","Stand (tree/ha)",
                               "Height AVG(m)","PV50(%)","Pits/ha","Arrow_survival","Arrow_stand","Arrow_height",
                               "ID_FARM","TALHAO"
        ]
        colunas_copiadas = ["cd_talhao2","Área(ha)","Data Plantio","Data Avaliação","Avaliação","GM","Média de PV50 CF",
                            "Ht (m)","Stand (tree/ha)","Média Pits/ha","Média de %_Sobrevivência","Arrow_PV50","Arrow_Ht",
                            "Arrow_Stand (tree/ha)","Arrow_Survival","Projeto","Talhão","Mês"]
        
        meses = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
                 "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
        
        base_path = os.path.abspath(paths[0])
        if "output" in base_path.lower():
            parent_dir = os.path.dirname(base_path)
            pasta_output = parent_dir
        else:
            base_dir = os.path.dirname(paths[0])
            pasta_output = os.path.join(base_dir, 'output')
        os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue
            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=17,header=1)

            novo_df = pd.DataFrame(columns=nomes_colunas_trans)

            print(df.head)

            novo_df["INDEX_2"] = df["Talhão"] 
            novo_df["INDEX"] = df["Talhão"]
            novo_df["Arrow_PV50"] = df["Arrow_PV50"]
            novo_df["Arrow_Stand (tree/ha)"] = df["Arrow_Stand (tree/ha)"]


            if "Data Avaliação" in df.columns:
                df["Data Avaliação"] = pd.to_datetime(df["Data Avaliação"], errors='coerce')
                novo_df["MONTHS"] = df["Data Avaliação"].dt.month.apply(lambda x: meses[x - 1] if pd.notnull(x) else None)
                novo_df["MONTH/YEAR MEASUREMENT"] = df["Data Avaliação"].dt.strftime('%Y')
                return True
            if "Data Plantio" in df.columns and "Data Avaliação" in df.columns:
                novo_df["AGE(DAYS)"] = (df["Data Avaliação"] - df["Data Plantio"]).dt.days
                return True
            nome_base = f"marcar_col"
            contador = 1
            destino = lambda c: os.path.join(pasta_output, f"{c}_{str(contador).zfill(2)}.xlsx")
            novo_arquivo = destino(nome_base)
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = destino(nome_base)

            novo_df.to_excel(novo_arquivo, index=False)
            print(f"Arquivo salvo como: {novo_arquivo}")

# Exemplo de uso
fazenda = farming()
arquivos = [r"/content/04_Base IFQ6_APRIL_Ht3_2025copia.xlsx"] 
fazenda.trans_colunas(arquivos)

TypeError: list indices must be integers or slices, not float
