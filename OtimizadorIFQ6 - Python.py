# Se a sequência não estiver correta em algum grupo, recalcula a sequência de NM_COVA
if bifurcacao_necessaria:
    # Para cada grupo (fila) reinicia a contagem de 1 até n
    for fila, grupo in df_final.groupby('NM_FILA'):
        indices = grupo.index.tolist()
        nova_sequencia = []
        contador = 1
        for pos, idx in enumerate(indices):
            cod = df_final.at[idx, 'CD_01']
            # Se for a primeira linha do grupo, atribui o contador
            if pos == 0:
                nova_sequencia.append(contador)
            else:
                if cod == 'L':
                    original_atual = df_final.at[idx, 'NM_COVA']
                    # Se o original for igual ao da linha anterior, repete o valor anterior
                    idx_ant = indices[pos - 1]
                    original_ant = df_final.at[idx_ant, 'NM_COVA']
                    if original_atual == original_ant:
                        nova_sequencia.append(nova_sequencia[-1])
                    # Caso contrário, se houver próxima linha e o original for igual ao da próxima linha, usa o valor que virá (depois incrementado) e marca "VERIFICAR"
                    elif pos < len(indices) - 1:
                        idx_prox = indices[pos + 1]
                        original_prox = df_final.at[idx_prox, 'NM_COVA']
                        if original_atual == original_prox:
                            contador += 1
                            nova_sequencia.append(contador)
                            df_final.at[idx, 'check SQC'] = 'VERIFICAR'
                        else:
                            contador += 1
                            nova_sequencia.append(contador)
                    else:
                        contador += 1
                        nova_sequencia.append(contador)
                else:
                    contador += 1
                    nova_sequencia.append(contador)
        # Atualiza os valores de NM_COVA para as linhas deste grupo
        for pos, idx in enumerate(indices):
            df_final.at[idx, 'NM_COVA'] = nova_sequencia[pos]
