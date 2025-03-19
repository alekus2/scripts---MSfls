python
import pandas as pd
import os 
import time

class OtimizadorIFQ6():
    def validação(codigos_adicionais, path_b1, path_b2, path_b3, coluna_codigos):
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
            raise FileNotFoundError(f"Erro: O arquivo '{path_b1}' não foi encontrado no diretório atual.")
        print("Tudo certo!")

        df = pd.read_excel(path_b1)
        df.columns = [coluna.upper() if coluna.lower() in (n.lower() for n in nomes_colunas) else coluna for coluna in df.columns]

        colunas_faltando = [coluna for coluna in nomes_colunas if coluna not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")

        # Filtragem das colunas com base nos códigos adicionais e na coluna especificada
        colunas_a_manter = [coluna for coluna in df.columns if coluna in nomes_colunas]

        # Verifica se a coluna especificada está nos dados e filtra os códigos de A a W
        if coluna_codigos in df.columns:
            # Filtra os códigos entre A e W
            codigos_validos = df[coluna_codigos].str.contains(r'^[A-W]$', na=False)
            colunas_a_manter += [coluna for coluna in df.columns if any(df[coluna_codigos][codigos_validos].str.contains(codigo) for codigo in codigos_adicionais)]
        
        df_filtrado = df[colunas_a_manter]

        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)

        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")
        time.sleep(3)

# Exemplo de uso
otimizador = OtimizadorIFQ6()
otimizador.validação(['CD_02'], '/content/Base_dados_EQ_01.xlsx', '', '', 'CD_01')
