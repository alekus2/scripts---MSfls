# Ordena o DataFrame apenas por NM_FILA e reseta o índice
df_filtrado = df_filtrado.sort_values(by=['NM_FILA']).reset_index(drop=True)

# Inicializa a coluna NM_COVA com 1 para a primeira linha
df_filtrado['NM_COVA'] = 1

# Itera sobre o DataFrame
for idx in range(1, len(df_filtrado)):
    # Se o valor de NM_FILA for igual ao da linha anterior, incrementa NM_COVA
    if df_filtrado.at[idx, 'NM_FILA'] == df_filtrado.at[idx - 1, 'NM_FILA']:
        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA'] + 1
    else:
        # Se NM_FILA mudar, reinicia NM_COVA para 1
        df_filtrado.at[idx, 'NM_COVA'] = 1
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

            # --- Contagem de NM_COVA por grupo (baseado em NM_FILA) ---
            df_filtrado = df_filtrado.sort_values(by=['NM_FILA']).reset_index(drop=True)
            df_filtrado['NM_COVA'] = 1  # valor inicial
            for idx in range(1, len(df_filtrado)):
                if df_filtrado.at[idx, 'NM_FILA'] == df_filtrado.at[idx - 1, 'NM_FILA']:
                    if df_filtrado.at[idx, 'CD_01'] == 'L':
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA']
                    else:
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA'] + 1
                else:
                    df_filtrado.at[idx, 'NM_COVA'] = 1

            # --- Ajuste do primeiro índice de cada grupo NM_COVA se CD_01 for 'L' ---
            # for nm_cova, grupo in df_filtrado.groupby('NM_COVA'):
            #     primeiro_indice = grupo.index[0]
            #     if df_filtrado.at[primeiro_indice, 'CD_01'] == 'L':
            #         df_filtrado.at[primeiro_indice, 'CD_01'] = 'N'
            #         print(f"Grupo NM_COVA {nm_cova}: alterado índice {primeiro_indice} de 'L' para 'N'.")

            # --- Contagem de NM_FUSTE por grupo de NM_COVA ---
            valid_letters = ('A','B','C','D','E','F','G','H','I','K','M','N','O','P','Q','R','S','T','U','V','W')
            # for nm_cova, grupo in df_filtrado.groupby('NM_COVA', sort=False):
            #     cont_fuste = 0  # reinicia para cada grupo
            #     for idx in sorted(grupo.index):
            #         if df_filtrado.at[idx, 'CD_01'] in valid_letters:
            #             cont_fuste = 1  # padrão para quando não for 'L'
            #             df_filtrado.at[idx, 'NM_FUSTE'] = cont_fuste
            #         else:  # para CD_01 igual a 'L'
            #             if cont_fuste < 2:
            #                 cont_fuste = 2
            #             else:
            #                 cont_fuste += 1
            #             df_filtrado.at[idx, 'NM_FUSTE'] = cont_fuste

            # --- Verificação de Duplicidade ---
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_filtrado['check dup'] = df_filtrado.duplicated(subset=dup_columns, keep=False)\
                                               .map({True: 'VERIFICAR', False: 'OK'})

            # --- Verificação dos Códigos em CD_01 ---
            # Para linhas onde CD_01 NÃO é "L": NM_FUSTE deve ser 1.
            df_filtrado['check cd'] = df_filtrado.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else None),
                axis=1
            )
            # Para linhas onde CD_01 é "L": NM_FUSTE deve ser >= 2.
            df_filtrado['check cd_02'] = df_filtrado.apply(
                lambda row: 'OK' if row['CD_01'] == 'L' and row['NM_FUSTE'] >= 2 else None,
                axis=1
            )

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
