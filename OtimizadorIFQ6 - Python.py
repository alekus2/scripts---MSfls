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

            # Inclui as colunas de código, se existirem
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

            # Determina a equipe a partir do nome do arquivo
            filename = os.path.basename(path)
            match = re.search(r'EQ_(\d+)', filename, re.IGNORECASE)
            equipe = f"ep_{match.group(1).zfill(2)}" if match else "ep_unknown"
            df_filtrado['EQUIPES'] = equipe

            # Inicializa NM_COVA. Aqui, para simplificar, a lógica atribui NM_COVA de forma sequencial:
            df_filtrado['NM_COVA'] = 1
            for idx in range(1, len(df_filtrado)):
                # Se a linha atual pertencer à mesma fila (NM_FILA) que a anterior, 
                # assume que se CD_01 for "L" o registro continua na mesma cova;
                # caso contrário, considera-se o início de uma nova cova.
                if df_filtrado.at[idx, 'NM_FILA'] == df_filtrado.at[idx - 1, 'NM_FILA']:
                    if df_filtrado.at[idx, 'CD_01'] == 'L':
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA']
                    else:
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA'] + 1
                else:
                    # Se mudar de NM_FILA, reinicia NM_COVA para 1
                    df_filtrado.at[idx, 'NM_COVA'] = 1

            # Se necessário, podemos ajustar CD_01 para o primeiro registro de cada NM_COVA
            # caso seja "L" e não haja "N" antes dentro do grupo.
            for nm_cova, grupo in df_filtrado.groupby('NM_COVA'):
                primeiro_indice = grupo.index[0]
                if df_filtrado.at[primeiro_indice, 'CD_01'] == 'L':
                    df_filtrado.at[primeiro_indice, 'CD_01'] = 'N'
                    print(f"Grupo NM_COVA {nm_cova}: alterado CD_01 no índice {primeiro_indice} de 'L' para 'N'.")

            # Agora, para contar o NM_FUSTE conforme a regra:
            # Para cada grupo de NM_COVA, percorre os registros e:
            # - Se CD_01 for "N", NM_FUSTE = 1.
            # - Se CD_01 for "L", o primeiro "L" recebe 2 e os subsequentes incrementam.
            for nm_cova, grupo in df_filtrado.groupby('NM_COVA'):
                cont_fuste = 1  # Para registros "N" o padrão é 1.
                for idx in grupo.index:
                    if df_filtrado.at[idx, 'CD_01'] == 'N':
                        cont_fuste = 1
                        df_filtrado.at[idx, 'NM_FUSTE'] = cont_fuste
                    else:  # Caso seja 'L'
                        if cont_fuste == 1:
                            cont_fuste = 2  # Primeiro 'L' passa a ser 2
                        else:
                            cont_fuste += 1
                        df_filtrado.at[idx, 'NM_FUSTE'] = cont_fuste

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
