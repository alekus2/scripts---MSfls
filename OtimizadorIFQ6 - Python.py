
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
                        print(f"Códigos válidos encontrados na coluna '{coluna_codigos}' no arquivo '{path}':")
                        print(df.loc[codigos_encontrados, coluna_codigos].unique())
                        colunas_a_manter.append(coluna_codigos)
                    else:
                        print(f"Nenhum código válido encontrado na coluna '{coluna_codigos}' no arquivo '{path}'. A coluna será criada no DataFrame final, mas estará vazia.")
                        df[coluna_codigos] = pd.NA
                        colunas_a_manter.append(coluna_codigos)
                else:
                    print(f"A coluna '{coluna_codigos}' não foi encontrada no arquivo '{path}'. A coluna será criada no DataFrame final, mas estará vazia.")
                    df[coluna_codigos] = pd.NA
                    colunas_a_manter.append(coluna_codigos)
            
            df_filtrado = df[colunas_a_manter].copy()
            
            df_filtrado['grupo'] = (df_filtrado['NM_FILA'] != df_filtrado['NM_FILA'].shift()).cumsum()
            df_filtrado['NM_COVA'] = df_filtrado.groupby('grupo').cumcount() + 1 
            df_filtrado.drop(columns=['grupo'], inplace=True)
            df_filtrado['CD_TALHAO'] = df_filtrado['CD_TALHAO'].astype(str).apply(lambda x: x.zfill(3)[-3:])
          
            filename = os.path.basename(path)
            match = re.search(r'EQ_(\d+)', filename, re.IGNORECASE)
            if match:
                equipe = f"ep_{match.group(1).zfill(2)}"
            else:
                equipe = "ep_unknown"
            df_filtrado['EQUIPES'] = equipe
            
            for col in ['CD_01', 'CD_02', 'CD_03']:
                if col in df_filtrado.columns:
                    df_filtrado['NM_COVA'] = df_filtrado.apply(
                        lambda row: row['NM_COVA'] - 1 if str(row[col]) == 'L' else row['NM_COVA'],
                        axis=1
                    )
            #VALIDAÇÕES PARA CORREÇÃO

            #dentro da planilha não pode existir 'nm_cova' == 0
            #para verificar se o L esta dentro da cova correta o codigo deverá ver se existe covas com codigos repetidos e conforme as repetiçoes desses deverá adicionar +1 em fuste ate acabar a cova que esta em processo.
            #exemplo: a 'nm_cova' é 1 e o 'cd_01' é N (caso contrario, não for N ele deverá alterar para N e continuar com as proximas verificações)  mas a proxima cova é 1 tambem e se o cd dela é  L então o fuste deverá ser == a 2, caso contrario deverá ajustar, e se a proxima cova for igual 1 denovo e cd for L o fuste deverá ser 3 e assim sucessivamente ate acabar esta 'nm_cova' ou seja suas repetições.
            #em vez de ser -1 ele deverá ser == a 'nm_cova' anterior se o 'cd_01' for == L e se a 'nm_cova' anterior for == N, pois se não seguir esta ordem ele deverá entrar em outra validação. 
            #se um grupo começar com 'cd_01' sendo L e a nm_cova for 1, 'cd_01' deverá ser == a N e sempre que tiver um L depois de um N o 'nm_fuste' tem que ser  == a 2 ou mais dependendo da quantidade de L que aparecer.
            #uma possivel solução seria criar uma coluna temporaria somente para verificar os L que irao aparecer e se ficaram de acordo com oque foi pedido.

            #CASO NÃO EXISTA JEITO DE FAZER ISSO.

            #o codigo então deverá apresentar ao usuario cada erro para que o usuario veja a contagem de erros e as verifique que no caso são as validações citadas acima.
            #a mensagem de erro tem que ser especifica dentro da junção das planihas ele deverá alterar a cor da linha em que o erro ocorreu para destacar este erro.
            #ele deverá mostrar a causa do erro e sua solução para o usuario saber oque deve ser feito.
            
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
