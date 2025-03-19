import pandas as pd
import os
import time
import string
import re

class OtimizadorIFQ6:
    def validacao(self, path_b1, path_b2, path_b3, coluna_codigos):
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
        
        # Lê o arquivo Excel e converte todos os nomes de colunas para maiúsculas
        df = pd.read_excel(path_b1)
        df.columns = [col.upper() for col in df.columns]
        
        # Verifica se as colunas obrigatórias estão presentes
        colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
        if colunas_faltando:
            raise KeyError(f"Erro: As colunas esperadas não foram encontradas: {', '.join(colunas_faltando)}")
        
        # Lista de colunas a manter (inicialmente as obrigatórias)
        colunas_a_manter = [col for col in df.columns if col in nomes_colunas]
        
        # Define as letras válidas (de A a W)
        valid_codes = [chr(i) for i in range(ord('A'), ord('W') + 1)]
        
        # Converte o parâmetro para maiúscula para padronização
        coluna_codigos = coluna_codigos.upper()
        
        # Se a coluna informada não existir, avisamos (mas vamos tentar extrair o código dela mesmo assim)
        if coluna_codigos not in df.columns:
            print(f"A coluna '{coluna_codigos}' não foi encontrada diretamente entre as colunas.")
        else:
            print(f"A coluna '{coluna_codigos}' foi encontrada.")
        
        # Agora, vamos tentar identificar um código válido a partir do nome da coluna informada.
        # Usaremos uma expressão regular para encontrar a primeira letra (A a W) no nome da coluna.
        match = re.search(r'([A-W])', coluna_codigos)
        if match:
            codigo_extraido = match.group(1)  # letra encontrada
            print(f"Código extraído do nome da coluna: {codigo_extraido}")
            # Se a coluna informada não existir com esse nome, mas existir outra coluna cujo nome contenha esse código,
            # podemos procurar entre todas as colunas.
            if coluna_codigos not in df.columns:
                for col in df.columns:
                    if codigo_extraido in col:
                        # Renomeia essa coluna para ficar apenas com a letra extraída
                        df = df.rename(columns={col: codigo_extraido})
                        print(f"A coluna '{col}' foi renomeada para '{codigo_extraido}'.")
                        break
            else:
                # Mesmo que a coluna exista, renomeamos para que seu nome seja somente o código extraído
                df = df.rename(columns={coluna_codigos: codigo_extraido})
                print(f"A coluna '{coluna_codigos}' foi renomeada para '{codigo_extraido}'.")
            
            # Agora, se a coluna com o código extraído não estiver na lista de colunas a manter, adiciona-a.
            if codigo_extraido not in colunas_a_manter:
                colunas_a_manter.append(codigo_extraido)
        else:
            print(f"Nenhuma letra válida (A a W) foi encontrada no nome da coluna '{coluna_codigos}'.")
        
        # Também podemos verificar se há outras colunas cujo nome seja exatamente uma letra válida
        for col in df.columns:
            if len(col) == 1 and col in valid_codes and col not in colunas_a_manter:
                colunas_a_manter.append(col)
        
        # Filtra o DataFrame para manter apenas as colunas desejadas
        df_filtrado = df[colunas_a_manter]
        
        # Salva o DataFrame filtrado em um novo arquivo Excel
        novo_arquivo_excel = r'/content/Base_padrao_estrutura_IFQ6_modificado.xlsx'
        df_filtrado.to_excel(novo_arquivo_excel, index=False)
        
        print(f"As colunas foram filtradas e o arquivo foi salvo como '{novo_arquivo_excel}'.")
        time.sleep(3)

# Exemplo de uso:
otimizador = OtimizadorIFQ6()
otimizador.validacao('/content/Base_dados_EQ_01.xlsx', '', '', 'cd_02')
