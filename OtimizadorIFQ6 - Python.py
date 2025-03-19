from logging import exception
import pandas as pd
import os

class OtimizadorIFQ6:
    def validacao(self, path_b1,path_b2,path_b3, cc1,cc2,):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01"
        ]
        
        if not os.path.exists(path_b1):
            raise FileNotFoundError(f"Erro: O arquivo '{path_b1}' não foi encontrado.")
        print("Tudo certo!")
        
        df = pd.read_excel(path_b1)
        
        df.columns = [col.upper() for col in df.columns]

    
        try:
            if cc2 or cc2 != '': 
              colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
              if colunas_faltando:
                  raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
              cc2 = cc2.upper()
              codigos_validos = [chr(i) for i in range(ord('A'), ord('X'))]
              colunas_a_manter = nomes_colunas.copy()
              if cc2 in df.columns:
                  print(df.head(10))
                  codigos_encontrados = df[cc2].astype(str).str.upper().isin(codigos_validos)
                  if codigos_encontrados.any():
                      print(f"Códigos válidos encontrados na coluna '{cc2}':")
                      print(df.loc[codigos_encontrados, cc2].unique())
                      colunas_a_manter.append(cc2)
                  else:
                      print(f"Nenhum código válido encontrado na coluna '{cc2}'. A coluna não será incluída no arquivo final.")
              else:
                  print(f"A coluna '{cc2}' não foi encontrada no DataFrame.")
            else:
              pass
        finally:
         df_filtrado = df[colunas_a_manter]
    
        try:
            if cc1 or cc1 != '': 
              colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
              if colunas_faltando:
                  raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
              cc1 = cc1.upper()
              codigos_validos = [chr(i) for i in range(ord('A'), ord('X'))]
              colunas_a_manter = nomes_colunas.copy()
              if cc1 in df.columns:
                  codigos_encontrados = df[cc1].astype(str).str.upper().isin(codigos_validos)
                  if codigos_encontrados.any():
                      print(f"Códigos válidos encontrados na coluna '{cc1}':")
                      print(df.loc[codigos_encontrados, cc1].unique())
                      colunas_a_manter.append(cc1)
                  else:
                      print(f"Nenhum código válido encontrado na coluna '{cc1}'. A coluna não será incluída no arquivo final.")
              else:
                  print(f"A coluna '{cc1}' não foi encontrada no DataFrame.")
            else:
              pass
        finally:
            df_filtrado = df[colunas_a_manter]
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)
        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")

otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_03.xlsx', 'cd_02','cd_03')
