import pandas as pd
import os
import re

class OtimizadorIFQ6:
    def validacao(self, paths, colunas_codigos):
        # Lista de colunas esperadas
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01", "CD_02", "CD_03"
        ]
        # Códigos válidos (A até W)
        codigos_validos = [chr(i) for i in range(ord('A'), ord('X'))]

        lista_df = []

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

            # Acrescenta as colunas de código especificadas, se necessário
            colunas_a_manter = nomes_colunas.copy()
            for coluna_codigos in colunas_codigos:
                coluna_codigos = coluna_codigos.upper()
                if coluna_codigos in df.columns:
                    if df[coluna_codigos].astype(str).str.upper().isin(codigos_validos).any():
                        colunas_a_manter.append(coluna_codigos)
                    else:
                        df[coluna_codigos] = pd.NA
                        colunas_a_manter.append(coluna_codigos)
                else:
                    df[coluna_codigos] = pd.NA
                    colunas_a_manter.append(coluna_codigos)

            df_filtrado = df[colunas_a_manter].copy()

            # Ajuste da coluna CD_TALHAO para os 3 últimos dígitos preenchidos com zeros à esquerda
            df_filtrado["CD_TALHAO"] = df_filtrado["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

            # Extrai a equipe a partir do nome do arquivo
            filename = os.path.basename(path)
            match = re.search(r'EQ_(\d+)', filename, re.IGNORECASE)
            equipe = f"ep_{match.group(1).zfill(2)}" if match else "ep_unknown"
            df_filtrado['EQUIPES'] = equipe

            # Define NM_COVA – neste exemplo, mantemos como 1
            df_filtrado['NM_COVA'] = 1

            # Observação: Não realizamos transformação da coluna NM_FUSTE, usando os valores já existentes.

            # --- Verificação de Duplicidade ---
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_filtrado['check dup'] = df_filtrado.duplicated(subset=dup_columns, keep=False)\
                                               .map({True: 'verificar', False: 'ok'})

            # --- Verificação dos Códigos em CD_01 ---
            # Para linhas onde CD_01 NÃO é "L": NM_FUSTE deve ser 1.
            df_filtrado['check cd'] = df_filtrado.apply(
                lambda row: 'ok' if row['CD_01'] != 'L' and row['NM_FUSTE'] == 1 else
                            ('verificar' if row['CD_01'] != 'L' else None),
                axis=1
            )

            # Para linhas onde CD_01 é "L": NM_FUSTE deve ser >= 2.
            df_filtrado['check cd_02'] = df_filtrado.apply(
                lambda row: 'ok' if row['CD_01'] == 'L' and row['NM_FUSTE'] >= 2 else
                            ('verificar' if row['CD_01'] == 'L' else None),
                axis=1
            )

            # Remove a coluna TEMP_FUSTE se existir (mantida do código original)
            if 'TEMP_FUSTE' in df_filtrado.columns:
                df_filtrado.drop(columns=['TEMP_FUSTE'], inplace=True)

            lista_df.append(df_filtrado)

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)
            novo_arquivo_excel = os.path.join(os.path.dirname(paths[0]), 'Base_dados_unificadas_modificado.xlsx')
            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"Todos os dados foram unificados e salvos como '{novo_arquivo_excel}'.")
        else:
            print("Nenhum arquivo foi processado com sucesso.")

# Exemplo de uso:
otimizador = OtimizadorIFQ6()
arquivos = [
    '/content/Base_dados_EQ_01.xlsx',
    '/content/Base_dados_EQ_02.xlsx',
    '/content/Base_dados_EQ_03.xlsx'
]
otimizador.validacao(arquivos, ['cd_02', 'cd_03'])
