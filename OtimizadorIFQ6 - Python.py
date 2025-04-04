import pandas as pd
import os
from datetime import datetime

class OtimizadorIFQ6:
    def validacao(self, paths):
        nomes_colunas = [
            "CD_PROJETO", "CD_TALHAO", "NM_PARCELA", "DC_TIPO_PARCELA",
            "NM_AREA_PARCELA", "NM_LARG_PARCELA", "NM_COMP_PARCELA",
            "NM_DEC_LAR_PARCELA", "NM_DEC_COM_PARCELA", "DT_INICIAL",
            "DT_FINAL", "CD_EQUIPE", "NM_LATITUDE", "NM_LONGITUDE",
            "NM_ALTITUDE", "DC_MATERIAL", "NM_FILA", "NM_COVA",
            "NM_FUSTE", "NM_DAP_ANT", "NM_ALTURA_ANT", "NM_CAP_DAP1",
            "NM_DAP2", "NM_DAP", "NM_ALTURA", "CD_01", "CD_02", "CD_03"
        ]
        
        lista_df = []
        equipes = {}

        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]
        data_emissao = datetime.now().strftime("%Y%m%d")

        base_dir = os.path.dirname(paths[0])
        pasta_mes = os.path.join(os.path.dirname(base_dir), nome_mes)
        pasta_output = os.path.join(pasta_mes, 'output')
        os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue

            nome_arquivo = os.path.basename(path).upper()
            if 'LEBATEC' in nome_arquivo:
                nome_equipe_base = "lebatec"
            elif 'BRAVORE' in nome_arquivo:
                nome_equipe_base = "bravore"
            elif 'PROPRIA' in nome_arquivo:
                nome_equipe_base = "propria"
            else:
                while True:
                    eqp = input("Selecione a equipe (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ")
                    if eqp in ['1', '2', '3']:
                        break
                nome_equipe_base = ["lebatec", "bravore", "propria"][int(eqp) - 1]

            equipes[nome_equipe_base] = equipes.get(nome_equipe_base, 0) + 1
            nome_equipe = nome_equipe_base if equipes[nome_equipe_base] == 1 else f"{nome_equipe_base}_{equipes[nome_equipe_base]:02d}"

            try:
                df = pd.read_excel(path, sheet_name=0)
            except Exception as e:
                print(f"Erro ao ler a primeira aba do arquivo '{path}': {e}")
                continue

            df.columns = [str(col).strip().upper() for col in df.columns]
            colunas_faltando = [col for col in nomes_colunas if col not in df.columns]

            if colunas_faltando:
                print(f"Colunas da planilha: {df.columns}")
                print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
                print("Vamos verificar na segunda aba...")
                try:
                    df = pd.read_excel(path, sheet_name=1)
                    df.columns = [str(col).strip().upper() for col in df.columns]
                    colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
                    if colunas_faltando:
                        print(f"Erro: As colunas esperadas não foram encontradas na segunda aba do arquivo '{path}': {', '.join(colunas_faltando)}")
                        continue
                    else:
                        print("Tudo certo, processando...")
                except Exception as e:
                    print(f"Erro ao ler a segunda aba do arquivo '{path}': {e}")
                    continue  

            df_filtrado = df[nomes_colunas].copy()
            df_filtrado['EQUIPE'] = nome_equipe
            lista_df.append(df_filtrado)

        if lista_df:
            df_final = pd.concat(lista_df, ignore_index=True)

            # Validação de duplicidade
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_final['check dup'] = df_final.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

            # Validação de CD_01 e NM_FUSTE
            valid_letters = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W')
            df_final['check cd'] = df_final.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK'),
                axis=1
            )

            df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

            # ––– Verificação da sequência de NM_COVA por NM_FILA –––
            # Função para verificar se a sequência de NM_COVA está conforme o esperado
            def is_sequential(group):
                last_value = None
                for _, row in group.iterrows():
                    if row['CD_01'] == 'L':
                        # Se for a primeira ocorrência, aceita o valor que está
                        if last_value is None:
                            last_value = row['NM_COVA']
                        else:
                            if row['NM_COVA'] != last_value:
                                return False
                    elif row['CD_01'] == 'N':
                        if last_value is None:
                            last_value = row['NM_COVA']
                        else:
                            if row['NM_COVA'] != last_value + 1:
                                return False
                            last_value = row['NM_COVA']
                return True

            # Checa se para cada NM_FILA a sequência já está correta
            bifurcacao_necessaria = False
            for fila, grupo in df_final.groupby('NM_FILA'):
                if not is_sequential(grupo):
                    bifurcacao_necessaria = True
                    break

            # Se a sequência não estiver na ordem, executa a verificação de bifurcação sem alterar os dados originais
            if bifurcacao_necessaria:
                df_final['check COVA'] = 'OK'
                ultima_bifurcacao = {}
                for idx in range(len(df_final)):
                    atual = df_final.iloc[idx]
                    nm_fila = atual['NM_FILA']
                    if nm_fila not in ultima_bifurcacao:
                        ultima_bifurcacao[nm_fila] = 0  # Inicia a contagem para essa fila

                    if atual['CD_01'] == 'L':
                        # Se for 'L', o valor de NM_COVA deve ser o último valor contado
                        if atual['NM_COVA'] != ultima_bifurcacao[nm_fila]:
                            df_final.at[idx, 'check COVA'] = 'VERIFICAR'
                    elif atual['CD_01'] == 'N':
                        # Se for 'N', o valor de NM_COVA deve ser o último valor contado + 1
                        if atual['NM_COVA'] != ultima_bifurcacao[nm_fila] + 1:
                            df_final.at[idx, 'check COVA'] = 'VERIFICAR'
                        ultima_bifurcacao[nm_fila] += 1  # Atualiza para o próximo valor esperado
            else:
                # Se a sequência estiver correta, apenas marca a verificação como OK, sem alterar dados
                df_final['check COVA'] = 'OK'

            # Validação adicional para check SQC
            df_final['check SQC'] = 'OK'  
            for idx in range(1, len(df_final)):
                atual = df_final.iloc[idx]
                anterior = df_final.iloc[idx - 1]
                if atual['NM_COVA'] == anterior['NM_COVA']:
                    if atual['CD_01'] == 'N' and anterior['CD_01'] == 'L' and anterior['NM_FUSTE'] == 2:
                        df_final.at[idx, 'check SQC'] = 'VERIFICAR'

            if len(equipes) == 1:
                nome_base = f"IFQ6_{nome_mes}_{list(equipes.keys())[0]}_{data_emissao}"
            elif len(equipes) == 2:
                nome_base = f"IFQ6_{list(equipes.keys())[0]}_e_{list(equipes.keys())[1]}_{data_emissao}"
            else:
                nome_base = f"IFQ6_{nome_mes}_{data_emissao}"

            contador = 1
            novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            while os.path.exists(novo_arquivo_excel):
                contador += 1
                novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")

            df_final.to_excel(novo_arquivo_excel, index=False)
            print(f"✅ Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
        else:
            print("❌ Nenhum arquivo foi processado com sucesso.")
          
# Exemplo de uso
otimizador = OtimizadorIFQ6()

arquivos = [
    "/content/IFQ6_MS_Florestal_Bravore_10032025.xlsx"
]

otimizador.validacao(arquivos)
