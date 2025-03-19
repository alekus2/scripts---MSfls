import pandas as pd
import os 
import time

class OtimizadorIFQ6():
    def validação(self, nomes_colunas, codigos_adicionais, path_b1, path_b2, path_b3):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01"
        ]

        arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6.xlsx'

        if not os.path.exists(arquivo_excel):
            raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")
        
        print("Tudo certo!")

        df = pd.read_excel(arquivo_excel, sheet_name=1)

        # Transformar colunas em maiúsculas se estiverem em minúsculas
        df.columns = [coluna.upper() if coluna.lower() in (n.lower() for n in nomes_colunas) else coluna for coluna in df.columns]

        # Verificar se todas as colunas esperadas estão presentes
        colunas_faltando = [coluna for coluna in nomes_colunas if coluna not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")

        # Filtrar colunas que estão em nomes_colunas ou contêm códigos adicionais
        colunas_a_manter = [coluna for coluna in df.columns if coluna in nomes_colunas or any(codigo in coluna for codigo in codigos_adicionais)]

        # Criar um novo DataFrame com as colunas filtradas
        df_filtrado = df[colunas_a_manter]

        # Salvando o DataFrame modificado em um novo arquivo Excel
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)

        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")

        time.sleep(3)

# Exemplo de uso
otimizador = OtimizadorIFQ6()
otimizador.validação([], ['codigo1', 'codigo2'], '', '', '')