import pandas as pd
import os
from datetime import datetime

class farming:
    def trans_colunas(self, paths):
        nomes_colunas_trans = [
            "INDEX_2", "MONTHS", "MONTH/YEAR MEASUREMENT", "PLANTED DATE", "MEASURING DATE", "AGE(DAYS)",
            "GM", "FARM", "INDEX", "GENETIC MATERIAL", "ÁREA(HA)", "Survival(%)", "Stand (tree/ha)",
            "Height AVG(m)", "PV50(%)", "Pits/ha", "Arrow_survival", "Arrow_height","Arrow_PV50","Arrow_stand",
            "ID_FARM", "TALHAO"
        ]
        colunas_map = {
            "cd_talhao2": "INDEX_2",
            "Data Plantio": "PLANTED DATE",
            "Data Avaliação": "MEASURING DATE",
            "GM": "GM",
            "Fazenda": "FARM",
            "cd_talhao2": "INDEX",
            "Clone":"GENETIC MATERIAL",
            "Área (ha)": "ÁREA(HA)",
            "Média de %_Sobrevivência": "Survival(%)",       
            "Stand (tree/ha)": "Stand (tree/ha)",
            "Ht (m)": "Height AVG(m)",
            "Média de PV50 CF": "PV50(%)",
            "Média Pits/ha": "Pits/ha",
            "Arrow_Survival": "Arrow_survival",
            "Arrow_Ht": "Arrow_height",
            "Arrow_PV50": "Arrow_PV50",
            "Arrow_Stand (tree/ha)": "Arrow_stand",
            "Projeto": "ID_FARM",
            "Talhão": "TALHAO",
        }

        meses = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
                 "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

        base_path = os.path.abspath(paths[0])
        if "output" in base_path.lower():
            pasta_output = os.path.dirname(base_path)
        else:
            pasta_output = os.path.join(os.path.dirname(base_path), 'output')
        os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue
            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=17, header=1)

            novo_df = pd.DataFrame(columns=nomes_colunas_trans)

            for col_orig, col_dest in colunas_map.items():
                if col_orig in df.columns:
                    novo_df[col_dest] = df[col_orig]

            if "Data Avaliação" in df.columns:
                df["Data Avaliação"] = pd.to_datetime(df["Data Avaliação"], errors='coerce')
                novo_df["MONTHS"] = (
                    df["Data Avaliação"]
                    .dt.month
                    .apply(lambda x: meses[int(x) - 1] if pd.notnull(x) else "")
                )
                novo_df["MONTH/YEAR MEASUREMENT"] = (
                    df["Data Avaliação"]
                    .dt.strftime('%Y')
                    .fillna('')
                )
                novo_df["MEASURING DATE"] = df["Data Avaliação"]

            if "Data Plantio" in df.columns and "Data Avaliação" in df.columns:
                df["Data Plantio"] = pd.to_datetime(df["Data Plantio"], errors='coerce')
                novo_df["PLANTED DATE"] = df["Data Plantio"]
                novo_df["AGE(DAYS)"] = (df["Data Avaliação"] - df["Data Plantio"]).dt.days

            for col in ["PV50(%)", "Survival(%)"]:
                if col in novo_df.columns:
                    novo_df[col] = (
                        pd.to_numeric(novo_df[col], errors='coerce')
                          .map(lambda x: f"{x:.1%}".replace(".", ",") if pd.notnull(x) else "")
                    )
            for col in ["ÁREA(HA)","Stand (tree/ha)", "Height AVG(m)", "Pits/ha"]:
                if col in novo_df.columns:
                    novo_df[col] = novo_df[col](int)

            # Gera nome de arquivo único
            nome_base = "marcar_col"
            contador = 1
            novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")

            # Salva
            novo_df.to_excel(novo_arquivo, index=False)
            print(f"Arquivo salvo como: {novo_arquivo}")

fazenda = farming()
arquivos = [r"/content/04_Base IFQ6_APRIL_Ht3_2025copia.xlsx"] 
fazenda.trans_colunas(arquivos)
