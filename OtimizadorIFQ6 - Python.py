import pandas as pd
import os
import time

class OtimizadorIFQ6:
    def validacao(self, path_b1, path_b2, path_b3, coluna_codigos):
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
        
        # Verifica se o arquivo existe
        if not os.path.exists(path_b1):
            raise FileNotFoundError(f"Erro: O arquivo '{path_b1}' não foi encontrado.")
        print("Tudo certo!")
        
        # Lê o arquivo Excel
        df = pd.read_excel(path_b1)
        # Converte os nomes das colunas para maiúsculas (para colunas que estão na lista de obrigatórias)
        df.columns = [col.upper() if col.lower() in [n.lower() for n in nomes_colunas] else col for col in df.columns]
        
        # Verifica se as colunas obrigatórias estão presentes
        colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
        
        # Converte o parâmetro para maiúsculas para garantir a padronização
        coluna_codigos = coluna_codigos.upper()
        
        # Verifica se a coluna informada existe no DataFrame
        if coluna_codigos not in df.columns:
            print(f"A coluna '{coluna_codigos}' não foi encontrada no DataFrame.")
        else:
            print(f"A coluna '{coluna_codigos}' encontrada. Mostrando as primeiras linhas:")
            print(df[coluna_codigos].head())
        
        # Começamos com as colunas obrigatórias
        colunas_a_manter = [col for col in df.columns if col in nomes_colunas]
        
        # Se a coluna informada existir e não estiver totalmente vazia
        if coluna_codigos in df.columns and not df[coluna_codigos].isnull().all():
            # Define os códigos válidos: letras de A a W
            valid_codes = [chr(i) for i in range(ord('A'), ord('W') + 1)]
            # Verifica se existe pelo menos um valor na coluna que seja uma letra válida
            # Convertendo os valores para string e para maiúsculas para a verificação
            mask = df[coluna_codigos].astype(str).str.upper().isin(valid_codes)
            if mask.any():
                print("Código válido encontrado na coluna:", coluna_codigos)
                # Inclui a coluna na lista a ser copiada, se ainda não estiver presente
                if coluna_codigos not in colunas_a_manter:
                    colunas_a_manter.append(coluna_codigos)
            else:
                print(f"Nenhum código válido (de A a W) foi encontrado na coluna '{coluna_codigos}'. A coluna não será copiada.")
        else:
            print(f"A coluna '{coluna_codigos}' está vazia ou não existe, portanto não será copiada.")
        
        # Filtra o DataFrame para manter somente as colunas obrigatórias e, se válida, a coluna de códigos
        df_filtrado = df[colunas_a_manter]
        
        # Salva o DataFrame filtrado em um novo arquivo Excel
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)
        
        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")
        time.sleep(3)

# Exemplo de uso:
otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_01.xlsx', '', '', 'cd_02')



Tudo certo!
A coluna 'cd_02' encontrada. Mostrando as primeiras linhas:
0    NaN
1    NaN
2    NaN
3    NaN
4    NaN
Name: cd_02, dtype: object
Código válido encontrado na coluna: cd_02
---------------------------------------------------------------------------
KeyError                                  Traceback (most recent call last)
<ipython-input-29-774fae4904aa> in <cell line: 0>()
     57 # Exemplo de uso:
     58 otimizador = OtimizadorIFQ6()
---> 59 otimizador.validacao('/content/Base_dados_EQ_01.xlsx', '', '', 'cd_02')

3 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/indexes/base.py in _raise_if_missing(self, key, indexer, axis_name)
   6250 
   6251             not_found = list(ensure_index(key)[missing_mask.nonzero()[0]].unique())
-> 6252             raise KeyError(f"{not_found} not in index")
   6253 
   6254     @overload

