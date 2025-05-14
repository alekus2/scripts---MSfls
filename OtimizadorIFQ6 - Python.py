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
            dup_columns = ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_FILA', 'NM_COVA', 'NM_FUSTE', 'NM_ALTURA']
            df_final['check dup'] = df_final.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})
            valid_letters = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W')
            df_final['check cd'] = df_final.apply(
                lambda row: 'OK' if row['CD_01'] in valid_letters and row['NM_FUSTE'] == 1 else
                            ('VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK'),
                axis=1
            )
            df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)
            def is_sequential(group):
                last_value = None
                for _, row in group.iterrows():
                    if row['CD_01'] == 'L':
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
            bifurcacao_necessaria = False
            for fila, grupo in df_final.groupby('NM_FILA'):
                if not is_sequential(grupo):
                    bifurcacao_necessaria = True
                    break
            df_final['check SQC'] = 'OK'
            df_final['NM_COVA_ORIG'] = df_final['NM_COVA']
            df_final['group_id'] = (df_final['NM_FILA'] != df_final['NM_FILA'].shift()).cumsum()

            if bifurcacao_necessaria:
                for group_id, grupo in df_final.groupby('group_id'):
                    indices = grupo.index.tolist()
                    nova_sequencia = list(range(1, len(indices) + 1))
                    for pos, idx in enumerate(indices):
                        if df_final.at[idx, 'CD_01'] == 'L':
                            original_atual = df_final.at[idx, 'NM_COVA_ORIG']
                            if pos > 0:
                                idx_ant = indices[pos - 1]
                                original_ant = df_final.at[idx_ant, 'NM_COVA_ORIG']
                                if original_atual == original_ant:
                                    nova_sequencia[pos] = nova_sequencia[pos - 1]
                                    continue
                            if pos < len(indices) - 1:
                                idx_prox = indices[pos + 1]
                                original_prox = df_final.at[idx_prox, 'NM_COVA_ORIG']
                                if original_atual == original_prox:
                                    nova_sequencia[pos] = nova_sequencia[pos + 1]
                                    df_final.at[idx, 'check SQC'] = 'VERIFICAR'
                                    continue
                    for pos, idx in enumerate(indices):
                        df_final.at[idx, 'NM_COVA'] = nova_sequencia[pos]
            else:
                for idx in range(1, len(df_final)):
                    atual = df_final.iloc[idx]
                    anterior = df_final.iloc[idx - 1]
                    if atual['NM_COVA'] == anterior['NM_COVA']:
                        if atual['CD_01'] == 'N' and anterior['CD_01'] == 'L' and anterior['NM_FUSTE'] == 2:
                            df_final.at[idx, 'check SQC'] = 'VERIFICAR'

            df_final.drop(columns=['NM_COVA_ORIG', 'group_id'], inplace=True)
            count_verificar = df_final['check SQC'].value_counts().get('VERIFICAR', 0)
            print(f"Quantidade de 'VERIFICAR': {count_verificar}")

            if count_verificar > 0:
                resposta = input("Deseja verificar a planilha agora? (s/n): ")
                if resposta.lower() == 's':
                    nome_base = f"IFQ6_{nome_mes}_{data_emissao}"
                    contador = 1
                    novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
                    while os.path.exists(novo_arquivo_excel):
                        contador += 1
                        novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
                    df_final.to_excel(novo_arquivo_excel, index=False)
                    print(f"✅ Dados verificados e salvos em '{novo_arquivo_excel}'.")
                else:
                  df_final['ht média'] = df_final.groupby(
                      ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA']
                  )['NM_ALTURA'].transform('mean')
                  df_final = df_final.sort_values(
                      by=['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'NM_ALTURA']
                  )
                  df_final['nm_cova_ordenado'] = df_final.groupby(
                      ['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA']
                  ).cumcount() + 1
                  df_final = df_final.sort_values(
                      by=['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'nm_cova_ordenado']
                  )
                  df_final['equipe_2'] = df_final['EQUIPE']
                  df_final['Dt_medição'] = df_final['DT_INICIAL']
                  df_final['chave_2'] = (
                      df_final['CD_PROJETO'].astype(str) + '-' +
                      df_final['CD_TALHAO'].astype(str) + '-' +
                      df_final['NM_PARCELA'].astype(str)
                  )
                  df_final['Ht_média'] = df_final['ht média'].apply(lambda x: f"{x:.1f}".replace('.',','))
                  df_final = df_final[['equipe_2','Dt_medição','chave_2','nm_cova_ordenado','Ht_média']]
                  nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
                  contador = 1
                  novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
                  while os.path.exists(novo_arquivo_excel):
                      contador += 1
                      novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
                  df_final.to_excel(novo_arquivo_excel, index=False)
                  print(f"✅ Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
            else:
              df_final['Ht média'] = df_final['NM_ALTURA'].fillna(0)
              df_final = df_final.sort_values(
                  by=['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'Ht média']
              )
              df_final['NM_COVA_ORDENADO'] = (
                  df_final
                    .groupby(['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA'])
                    .cumcount() + 1
              )
              df_final['CHAVE_2'] = (
                  df_final['CD_PROJETO'].astype(str) + '-' +
                  df_final['CD_TALHAO'].astype(str) + '-' +
                  df_final['NM_PARCELA'].astype(str)
              )
              df_final['DT_MEDIÇÃO1'] = df_final['DT_INICIAL']
              df_final['EQUIPE_2'] = df_final['CD_EQUIPE']
              df_final.drop(columns=['check dup','check cd','check SQC'], inplace=True)

              cadastro_path = paths[-1]
              df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
              df_cadastro['Index'] = df_cadastro['Id Projeto'].str.strip() + df_cadastro['Talhão'].str.strip()
              df_final['Index'] = df_final['CD_PROJETO'].astype(str).str.strip() + df_final['CD_TALHAO'].astype(str).str.strip()
              df_res = pd.merge(
                  df_final,
                  df_cadastro[['Index', 'Área(ha)']],
                  on='Index',
                  how='left'
              )
              df_res.rename(columns={
                  'chave_2': 'Chave_stand_1',
                  'NM_PARCELA': 'nm_parcela',
                  'NM_AREA_PARCELA': 'nm_area_parcela'
              }, inplace=True)
              cols_iniciais = [
                  'Área(ha)', 'Chave_stand_1',
                  'CD_PROJETO', 'CD_TALHAO',
                  'nm_parcela', 'nm_area_parcela'
              ]
              df_res = df_res[cols_iniciais + ['nm_cova_ordenado', 'Ht_média']]
              df_pivot = df_res.pivot_table(
                  index=cols_iniciais,
                  columns='nm_cova_ordenado',
                  values='Ht_média',
                  aggfunc='first'
              ).reset_index()
              df_pivot.columns = [
                  str(c) if isinstance(c, int) else c
                  for c in df_pivot.columns
              ]
              num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=lambda x: int(x))
              df_tabela_resultados = df_pivot[cols_iniciais + num_cols]

              nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
              contador = 1
              path_saida = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
              while os.path.exists(path_saida):
                  contador += 1
                  path_saida = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")

              with pd.ExcelWriter(path_saida, engine='openpyxl') as writer:
                  df_cadastro.to_excel(writer, sheet_name='Cadastro_SGF', index=False)
                  df_final.to_excel(writer, sheet_name=f'Dados_CST_{nome_mes}', index=False)
                  df_tabela_resultados.to_excel(writer, sheet_name='C_tabela_resultados', index=False)

              print(f"✅ Tudo gravado em '{path_saida}'")
        else:
              print("❌ Nenhum arquivo foi processado com sucesso.")

otimizador = OtimizadorIFQ6()

arquivos = [
      "/content/6271_TABOCA_SRP - IFQ6 (4).xlsx",
      "/content/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx",
      "/content/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx",
      "/content/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx",
      "/content/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx",
      "/content/6371_SÃO_ROQUE_BTG - IFQ6 (
