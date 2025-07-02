

import pandas as pd
import os
from datetime import datetime

class Farming:
    def copiar_dados_especificos(self, paths):
        nomes_colunas_trans = [
            "Compartment_2", "Months", "Year/Month Measurement", "Planted Date", "Age (days)",
            "Classe Age", "Season", "GM", "Season - Group of Material Genetic", "Farm",
            "Compartment", "Genetic Material", "Area (ha)", "Survival (%)", "Stand (tree/ha)",
            "Height Avg (m)", "PV50 (%)", "Accumulated Rainfall (mm)*", "Pits/ha", "Arrow_Survival",
            "Arrow_Stand", "Arrow_PV50", "Arrow_Height", "Survival (%) * Area", "Stand (tree/ha) * Area",
            "Pits/há*Area", "Heigth Avg (m) * Area", "PV50      (%) * Area", "Accumulated Rainfall (mm)*Area",
            "EPS", "num talhão", "ID_Farm", "Stand inicial", "INDEX", "Final classification", "Trim",
            "Ano medição", "Stand inicial 2", "Stand inicial -ajustado"
        ]
        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
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
            xls = pd.ExcelFile(path)
            if "IFQ6" in xls.sheet_names:
                df = pd.read_excel(path, sheet_name="IFQ6", header=1)
            else:
                print("Erro: Planilha 'IFQ6' não encontrada.")
                continue

            novo_df = pd.DataFrame(columns=nomes_colunas_trans)
            colunas_encontradas = []

            for col in nomes_colunas_trans:
                if col in df.columns:
                    novo_df[col] = df[col]
                    colunas_encontradas.append(col)
                else:
                    print(f"A coluna '{col}' não foi encontrada.")
            if "Final classification" in novo_df.columns:
                mapeamento = {
                    "Bad":   1,
                    "Weak":  2,
                    "Good":  3,
                    "Great": 4
                }
                novo_df["Ordem Class"] = novo_df["Final classification"].map(mapeamento)
            ano_atual = datetime.now().year
            novo_df["Ordem Mês"] = ""
            mapeamento = {
                "January":   1, "February":  2, "March":     3,
                "April":     4, "May":       5, "June":      6,
                "July":      7, "August":    8, "September": 9,
                "October":  10, "November": 11, "December": 12
            }
            mask = novo_df["Year/Month Measurement"] == ano_atual
            novo_df.loc[mask, "Month"] = novo_df.loc[mask, "Months"].str.split("/").str[0]
            novo_df.loc[mask, "Ordem Mês"] = novo_df.loc[mask, "Month"].map(mapeamento)
            novo_df.drop(columns=["Month"], inplace=True)
            if "Final classification" in novo_df.columns:
                mapeamento = {
                    "Bad":   "BW",
                    "Weak":  "BW",
                    "Good":  "GG",
                    "Great": "GG"
                }
                novo_df["Porcentagem GGs"] = novo_df["Final classification"].map(mapeamento)            
            
            for col in ["PV50 (%)", "Survival (%)"]:
                if col in novo_df.columns:
                    novo_df[col] = (
                        pd.to_numeric(novo_df[col], errors='coerce')
                        .map(lambda x: f"{x:.1%}".replace(".", ",") if pd.notnull(x) else "")
                    )
            for col in ["Stand (tree/ha)", "Pits/ha", "Accumulated Rainfall (mm)*",
                         "Survival (%) * Area", "Heigth Avg (m) * Area", "PV50      (%) * Area"]:
                if col in novo_df.columns:
                    novo_df[col] = novo_df[col].round(2)

            mes_atual = meses[datetime.now().month - 1]
            nome_base = f"IFQ6_{mes_atual}"
            contador = 1
            novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")

            novo_df.to_excel(novo_arquivo, index=False)
            print(f"Arquivo salvo como: {novo_arquivo}")

fazenda = Farming()
arquivos = [r"/content/04_Base IFQ6_APRIL_Ht3_2025copia.xlsx"] 
fazenda.copiar_dados_especificos(arquivos)
