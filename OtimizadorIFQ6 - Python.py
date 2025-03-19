import pandas as pd
import os

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
        
        # Verifica se o arquivo existe
        if not os.path.exists(path_b1):
            raise FileNotFoundError(f"Erro: O arquivo '{path_b1}' não foi encontrado.")
        print("Tudo certo!")
        
        # Lê o arquivo Excel
        df = pd.read_excel(path_b1)
        
        # Converte os nomes das colunas para maiúsculas
        df.columns = [col.upper() for col in df.columns]
        
        # Verifica se as colunas obrigatórias estão presentes
        colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
        
        # Converte o nome da coluna de códigos para maiúsculas
        coluna_codigos = coluna_codigos.upper()
        
        # Lista de códigos válidos: letras de A a W
        codigos_validos = [chr(i) for i in range(ord('A'), ord('X'))]
        
        # Inicializa a lista de colunas a serem mantidas com as colunas obrigatórias
        colunas_a_manter = nomes_colunas.copy()
        
        # Verifica se a coluna de códigos existe no DataFrame
        if coluna_codigos in df.columns:
            # Filtra os valores válidos na coluna de códigos
            codigos_encontrados = df[coluna_codigos].astype(str).str.upper().isin(codigos_validos)
            if codigos_encontrados.any():
                # Exibe os códigos válidos encontrados
                print(f"Códigos válidos encontrados na coluna '{coluna_codigos}':")
                print(df.loc[codigos_encontrados, coluna_codigos].unique())
                
                # Inclui a coluna de códigos na lista de colunas a serem mantidas
                colunas_a_manter.append(coluna_codigos)
            else:
                print(f"Nenhum código válido encontrado na coluna '{coluna_codigos}'. A coluna não será incluída no arquivo final.")
        else:
            print(f"A coluna '{coluna_codigos}' não foi encontrada no DataFrame.")
        
        # Filtra o DataFrame para manter apenas as colunas selecionadas
        df_filtrado = df[colunas_a_manter]
        
        # Salva o DataFrame filtrado em um novo arquivo Excel
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)
        
        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")

# Exemplo de uso:
otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_01.xlsx', 'cd_02')
