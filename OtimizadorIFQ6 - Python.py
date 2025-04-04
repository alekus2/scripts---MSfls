# ...
            # Se a sequência não estiver correta em algum grupo, recalcula a sequência de NM_COVA
            if bifurcacao_necessaria:
                # Para cada grupo (fila), reinicia a contagem de 1 até n
                for fila, grupo in df_final.groupby('NM_FILA'):
                    indices = grupo.index.tolist()
                    tamanho = len(indices)
                    # Gera uma sequência base: [1, 2, ..., n]
                    nova_sequencia = list(range(1, tamanho + 1))
                    
                    # Ajusta para linhas com código "L" conforme as condições descritas
                    for pos, idx in enumerate(indices):
                        if df_final.at[idx, 'CD_01'] == 'L':
                            original_atual = df_final.at[idx, 'NM_COVA']
                            # Verifica se há linha anterior e se o valor original é igual ao da linha anterior
                            if pos > 0:
                                idx_ant = indices[pos - 1]
                                original_ant = df_final.at[idx_ant, 'NM_COVA']
                                if original_atual == original_ant:
                                    nova_sequencia[pos] = nova_sequencia[pos - 1]
                                    continue  # Se a condição for satisfeita, não verifica a próxima
                            # Verifica se há linha seguinte e se o valor original é igual ao da linha seguinte
                            if pos < tamanho - 1:
                                idx_prox = indices[pos + 1]
                                original_prox = df_final.at[idx_prox, 'NM_COVA']
                                if original_atual == original_prox:
                                    nova_sequencia[pos] = nova_sequencia[pos + 1]
                                    df_final.at[idx, 'check SQC'] = 'VERIFICAR'
                                    continue
                    # Atualiza os valores de NM_COVA para as linhas deste grupo
                    for pos, idx in enumerate(indices):
                        df_final.at[idx, 'NM_COVA'] = nova_sequencia[pos]
# ...
