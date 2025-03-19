
import pandas as pd
import os
import time

class OtimizadorIFQ6:
    def validacao(self, path_b1, coluna_codigos):
        # Lista de colunas obrigatórias esperadas
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
        
        colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
        
        coluna_codigos = coluna_codigos.upper()
        
        codigos_validos = ['O']
        
        if df[coluna_codigos].isnull().all():
            print(f"A coluna '{coluna_codigos}' não contém dados.")
            return
        else: 
          print('tem alguma coisa')
              
        colunas_a_manter = nomes_colunas.copy()
        
        if coluna_codigos in df.columns:
            if df[coluna_codigos].astype(str).str.upper().isin(codigos_validos).any():
                print(f"Códigos válidos encontrados na coluna '{coluna_codigos}'. A coluna será incluída no arquivo final.")
                colunas_a_manter.append(coluna_codigos)
            else:
                print(f"Nenhum código válido encontrado na coluna '{coluna_codigos}'. A coluna não será incluída no arquivo final.")
        else:
            print(f"A coluna '{coluna_codigos}' não foi encontrada no DataFrame.")
        
        df_filtrado = df[colunas_a_manter]
        
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)
        
        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")

otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_01.xlsx', 'cd_02')
