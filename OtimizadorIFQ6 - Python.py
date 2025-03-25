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
