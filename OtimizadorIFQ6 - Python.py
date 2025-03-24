import pandas as pd
import os
import re

class OtimizadorIFQ6:
    def validacao(self, paths, colunas_codigos):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01", "CD_02", "CD_03"
        ]
        
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
            
            colunas_a_manter = nomes_colunas.copy()
            for coluna_codigos in colunas_codigos:
                coluna_codigos = coluna_codigos.upper()
                if coluna_codigos in df.columns:
                    codigos_encontrados = df[coluna_codigos].astype(str).str.upper().isin(codigos_validos)
                    if codigos_encontrados.any():
                        colunas_a_manter.append(coluna_codigos)
                    else:
                        df[coluna_codigos] = pd.NA
                        colunas_a_manter.append(coluna_codigos)
                else:
                    df[coluna_codigos] = pd.NA
                    colunas_a_manter.append(coluna_codigos)
            
            df_filtrado = df[colunas_a_manter].copy()
            
            df_filtrado['grupo'] = (df_filtrado['NM_FILA'] != df_filtrado['NM_FILA'].shift()).cumsum()
            df_filtrado['NM_COVA'] = 1
            
            filename = os.path.basename(path)
            match = re.search(r'EQ_(\d+)', filename, re.IGNORECASE)
            equipe = f"ep_{match.group(1).zfill(2)}" if match else "ep_unknown"
            df_filtrado['EQUIPES'] = equipe
            
            df_filtrado['TEMP_FUSTE'] = 1
            
            for idx in range(1, len(df_filtrado)):
                atual = df_filtrado.iloc[idx]
                anterior = df_filtrado.iloc[idx - 1]

                if atual['NM_FILA'] == anterior['NM_FILA']:
                    if atual['CD_01'] == 'L':
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA']
                        if anterior['CD_01'] == 'N':
                            df_filtrado.at[idx, 'TEMP_FUSTE'] = 2
                        else:
                            df_filtrado.at[idx, 'TEMP_FUSTE'] = df_filtrado.at[idx - 1, 'TEMP_FUSTE'] + 1
                    else:
                        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA'] + 1
                        df_filtrado.at[idx, 'TEMP_FUSTE'] = 1
            
            df_filtrado['NM_FUSTE'] = df_filtrado['TEMP_FUSTE']
            df_filtrado.drop(columns=['TEMP_FUSTE', 'grupo'], inplace=True)

            # Verificar e corrigir o primeiro 'L' em cada grupo de NM_COVA
            for (nm_fila, nm_cova), grupo in df_filtrado.groupby(['NM_FILA', 'NM_COVA']):
                primeiro_index = grupo.index[0]
                
                # Se o primeiro registro do grupo for 'L', altera para 'N'
                if df_filtrado.at[primeiro_index, 'CD_01'] == 'L':
                    print(f"Ajustando NM_FILA {nm_fila}, NM_COVA {nm_cova}: Alterando 'L' para 'N'.")
                    df_filtrado.at[primeiro_index, 'CD_01'] = 'N'

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
