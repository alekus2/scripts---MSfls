import pandas as pd
import os
from datetime import datetime

class farming:
    def trans_colunas(self, paths):
        nomes_colunas_trans = [
            "INDEX_2", "MONTHS", "MONTH/YEAR MEASUREMENT", "PLANTED DATE", "MEASURING DATE", "AGE(DAYS)",
            "GM", "FARM", "INDEX", "GENETIC MATERIAL", "ÁREA(HA)", "Survival(%)", "Stand (tree/ha)",
            "Height AVG(m)", "PV50(%)", "Pits/ha", "Arrow_survival", "Arrow_stand", "Arrow_height",
            "ID_FARM", "TALHAO"
        ]
        colunas_map = {
            "cd_talhao2": "INDEX_2",
            "Área(ha)": "ÁREA(HA)",
            "Data Plantio": "PLANTED DATE",
            "Data Avaliação": "MEASURING DATE",
            "Avaliação": "FARM",
            "GM": "GM",
            "Média de PV50 CF": "PV50(%)",
            "Ht (m)": "Height AVG(m)",
            "Stand (tree/ha)": "Stand (tree/ha)",
            "Média Pits/ha": "Pits/ha",
            "Média de %_Sobrevivência": "Survival(%)",
            "Arrow_PV50": "Arrow_survival",        # atenção ao nome destino
            "Arrow_Ht": "Arrow_height",
            "Arrow_Stand (tree/ha)": "Arrow_stand",
            "Arrow_Survival": "Arrow_survival",
            "Projeto": "ID_FARM",
            "Talhão": "TALHAO",
            "Mês": "MONTHS"
        }

        meses = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
                 "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

        # Define pasta de saída
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

            # Cria DataFrame novo com colunas na ordem desejada
            novo_df = pd.DataFrame(columns=nomes_colunas_trans)

            # Mapeia colunas originais para as novas
            for col_orig, col_dest in colunas_map.items():
                if col_orig in df.columns:
                    novo_df[col_dest] = df[col_orig]

            # Converte datas
            if "Data Avaliação" in df.columns:
                df["Data Avaliação"] = pd.to_datetime(df["Data Avaliação"], errors='coerce')
                # MONTHS: converte para int antes de indexar
                novo_df["MONTHS"] = (
                    df["Data Avaliação"]
                    .dt.month
                    .apply(lambda x: meses[int(x) - 1] if pd.notnull(x) else "")
                )
                # YEAR measurement (coluna de ano)
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

            # Formata colunas percentuais como '0,0%'
            for col in ["PV50(%)", "Survival(%)"]:
                if col in novo_df.columns:
                    novo_df[col] = (
                        pd.to_numeric(novo_df[col], errors='coerce')
                          .map(lambda x: f"{x:.1%}".replace(".", ",") if pd.notnull(x) else "")
                    )

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
