# Salva os valores originais de NM_COVA para referência
df_final['NM_COVA_ORIG'] = df_final['NM_COVA']

# Cria um identificador de grupo para cada bloco contíguo de NM_FILA
df_final['group_id'] = (df_final['NM_FILA'] != df_final['NM_FILA'].shift()).cumsum()

# Se a sequência não estiver correta em algum grupo, recalcula a sequência de NM_COVA
if bifurcacao_necessaria:
    # Para cada grupo (bloco contíguo de NM_FILA), a contagem sequencial reinicia de 1 até n
    for group_id, grupo in df_final.groupby('group_id'):
        indices = grupo.index.tolist()
        # Gera a sequência padrão para o grupo: [1, 2, ..., n]
        nova_sequencia = list(range(1, len(indices) + 1))
        
        # Ajusta apenas as linhas com código "L"
        for pos, idx in enumerate(indices):
            if df_final.at[idx, 'CD_01'] == 'L':
                original_atual = df_final.at[idx, 'NM_COVA_ORIG']
                # Se existir linha anterior e os valores originais forem iguais, repete o valor anterior
                if pos > 0:
                    idx_ant = indices[pos - 1]
                    original_ant = df_final.at[idx_ant, 'NM_COVA_ORIG']
                    if original_atual == original_ant:
                        nova_sequencia[pos] = nova_sequencia[pos - 1]
                        continue
                # Se existir linha seguinte e os valores originais forem iguais, utiliza o valor da próxima linha e marca "VERIFICAR"
                if pos < len(indices) - 1:
                    idx_prox = indices[pos + 1]
                    original_prox = df_final.at[idx_prox, 'NM_COVA_ORIG']
                    if original_atual == original_prox:
                        nova_sequencia[pos] = nova_sequencia[pos + 1]
                        df_final.at[idx, 'check SQC'] = 'VERIFICAR'
                        continue
        
        # Atualiza os valores de NM_COVA para as linhas deste grupo com a nova sequência
        for pos, idx in enumerate(indices):
            df_final.at[idx, 'NM_COVA'] = nova_sequencia[pos]

# Remove as colunas auxiliares, se desejar
df_final.drop(columns=['NM_COVA_ORIG', 'group_id'], inplace=True)
