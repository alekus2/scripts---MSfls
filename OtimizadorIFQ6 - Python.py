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
