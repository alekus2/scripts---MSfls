
import pandas as pd
import os
from datetime import datetime

class farming:
    def copiar_dados_especificos(self, paths):
        nomes_colunas_trans = ["Compartment_2",	"Months",	"Year/Month Measurement",	"Planted Date",	"Age (days)",	"Classe Age",	"Season",	"GM",	"Season - Group of Material Genetic",
                               "Farm",	"Compartment",	"Genetic Material",	"Area (ha)",	"Survival (%)",	"Stand (tree/ha)",	"Height Avg (m)",	"PV50 (%)",	"Accumulated Rainfall (mm)*",	"Pits/ha",	"Arrow_Survival",
                               "Arrow_Stand",	"Arrow_PV50",	"Arrow_Height",	"Survival (%) * Area",	"Stand (tree/ha) * Area",
                               "Pits/há*Area",	"Heigth Avg (m) * Area",	"PV50      (%) * Area",	"Accumulated Rainfall (mm)*Area",	"EPS",	"num talhão",	"ID_Farm",	"Stand inicial", "INDEX",
                               "Final classification",	"Trim",	"Ano medição",	"Stand inicial 2",	"Stand inicial -ajustado"
        ]

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
            df = pd.read_excel(path, sheet_name=17, header=1) #quero que ele caçe o sheet com o nome "IFQ6" dentro do arquivo do excel q mandei,ja que existe varias planilhas dentro dele.

            novo_df = pd.DataFrame(columns=nomes_colunas_trans) #Como agora ele so vai copiar dados especificos quero que ele copie so aqls colunas que estao em nomes_colunas de dentro do arquivo q esta inserido, assim criando um arquivo separado so para ele.
            #se nao encontrar alguma coluna lançar um print do nome da coluna q nao foi encontrada e criar um arquivo com as colunas q foram encontradas.
            
            if nomes_colunas_trans in df.columns:
               novo_df = df

            for col in ["PV50(%)", "Survival(%)"]:
                if col in novo_df.columns:
                    novo_df[col] = (
                        pd.to_numeric(novo_df[col], errors='coerce')
                          .map(lambda x: f"{x:.1%}".replace(".", ",") if pd.notnull(x) else "")
                    )
            for col in ["ÁREA(HA)","Stand (tree/ha)", "Height AVG(m)", "Pits/ha"]:
                if col in novo_df.columns:
                    novo_df[col] = novo_df[col](int)

            nome_base = "IFQ6"
            contador = 1
            novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx") #quero que coloque o nome do mes atual no arquivo final tb

            # Salva
            novo_df.to_excel(novo_arquivo, index=False)
            print(f"Arquivo salvo como: {novo_arquivo}")

fazenda = farming()
arquivos = [r"/content/04_Base IFQ6_APRIL_Ht3_2025copia.xlsx"] 
fazenda.copiar_dados_especificos(arquivos)
