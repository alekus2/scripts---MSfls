import pandas as pd
import os 
import time

class OtimizadorIFQ6():
  def validação(self,nomes_colunas,path_b1,path_b2,path_b3):
    nomes_colunas = ["CD_PROJETO",
                     "CD_TALHAO",
                     "NM_PARCELA",
                     "DC_TIPO_PARCELA",
                     "NM_AREA_PARCELA",
                     "NM_LARG_PARCELA",
                     "NM_COMP_PARCELA",
                     "NM_DEC_LAR_PARCELA",
                     "NM_DEC_COM_PARCELA",
                     "DT_INICIAL",
                     "DT_FINAL",
                     "CD_EQUIPE",
                     "NM_LATITUDE",
                     "NM_LONGITUDE",
                     "NM_ALTITUDE",
                     "DC_MATERIAL",
                     "NM_FILA",
                     "NM_COVA",
                     "NM_FUSTE",
                     "NM_DAP_ANT",
                     "NM_ALTURA_ANT",
                     "NM_CAP_DAP1",
                     "NM_DAP2",
                     "NM_DAP",
                     "NM_ALTURA",
                     "CD_01"
                     ]
    try:
       arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6.xlsx'

       if not os.path.exists(arquivo_excel):
        raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")
       else:
        print("Tudo certo!")

       df = pd.read_excel(arquivo_excel, sheet_name=1)


       for coluna in nomes_colunas:
            if coluna not in df.columns:
                raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")
       titulos = df['Titulo'].astype(str).values
       nomes = df['Nome'].astype(str).values
       valores_real = df['Valores Reais'].fillna(0).values
       valores_plano = df['Plano'].fillna(0).values
    finally:
     time.sleep(3)
     quit
