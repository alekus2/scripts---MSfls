import pandas as pd
import os

class OtimizadorIFQ6:
    def validacao(self, paths, colunas_codigos):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01"
        ]
        
        codigos_validos = [chr(i) for i in range(ord('A'), ord('X'))]
        
        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: O arquivo '{path}' não foi encontrado.")
                continue
            print(f"Processando o arquivo: {path}")
            
            df = pd.read_excel(path)
            
            df.columns = [col.upper() for col in df.columns]
            
            colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
            if colunas_faltando:
                print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
                continue
            
            colunas_a_manter = nomes_colunas.copy()
            
            for coluna_codigos in colunas_codigos:
                coluna_codigos = coluna_codigos.upper()
                
                if coluna_codigos in df.columns:
                    codigos_encontrados = df[coluna_codigos].astype(str).str.upper().isin(codigos_validos)
                    if codigos_encontrados.any():
                        print(f"Códigos válidos encontrados na coluna '{coluna_codigos}' no arquivo '{path}':")
                        print(df.loc[codigos_encontrados, coluna_codigos].unique())
                        
                        colunas_a_manter.append(coluna_codigos)
                    else:
                        print(f"Nenhum código válido encontrado na coluna '{coluna_codigos}' no arquivo '{path}'. A coluna não será incluída no arquivo final.")
                else:
                    print(f"A coluna '{coluna_codigos}' não foi encontrada no arquivo '{path}'.")
            
            df_filtrado = df[colunas_a_manter]

            # Adiciona a coluna NM_FILA com valores de 1 a 7 repetidamente
            df_filtrado['NM_FILA'] = ((df_filtrado.index % 7) + 1).astype(int)

            # Adiciona a coluna NM_COVA com valores sequenciais dentro de cada NM_FILA
            df_filtrado['NM_COVA'] = df_filtrado.groupby('NM_FILA').cumcount() + 1

            novo_arquivo_excel = os.path.splitext(path)[0] + '_modificado.xlsx'
            df_filtrado.to_excel(novo_arquivo_excel, index=False)
            print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.\n")

# Exemplo de uso:
otimizador = OtimizadorIFQ6()
arquivos = [
    '/content/Base_dados_EQ_01.xlsx',
    '/content/Base_dados_EQ_02.xlsx',
    '/content/Base_dados_EQ_03.xlsx'
]
otimizador.validacao(arquivos, ['cd_02', 'cd_03'])
