import pandas as pd
import os 
import time

class OtimizadorIFQ6:
    def validacao(self, path_b1, path_b2, path_b3, coluna_codigos):
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
        df.columns = [
            coluna.upper() if coluna.lower() in (n.lower() for n in nomes_colunas) else coluna
            for coluna in df.columns
        ]

        colunas_faltando = [coluna for coluna in nomes_colunas if coluna not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")

        if coluna_codigos not in df.columns:
            raise KeyError(f"Erro: A coluna '{coluna_codigos}' não foi encontrada.")

        print(f"A coluna '{coluna_codigos}' existe. Mostrando as primeiras linhas dessa coluna:")
        print(df[coluna_codigos].head())

        colunas_a_manter = [coluna for coluna in df.columns if coluna in nomes_colunas]

        if df[coluna_codigos].isnull().all():
            print(f"A coluna '{coluna_codigos}' não contém dados.")
            return  

        codigos_validos = df[coluna_codigos].astype(str).str.match(['A','B','C'...])

        if codigos_validos.any():
            df.loc[codigos_validos, coluna_codigos] = df.loc[codigos_validos, coluna_codigos].str.upper()
            colunas_a_manter.append(coluna_codigos)

        df_filtrado = df[colunas_a_manter]

        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)

        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")
        time.sleep(3)

otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_01.xlsx', '', '', 'cd_02')S
