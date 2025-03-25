for idx in range(1, len(df_filtrado)):
    atual = df_filtrado.iloc[idx]
    anterior = df_filtrado.iloc[idx - 1]

    if atual['NM_COVA'] == anterior['NM_COVA']:
        if atual['CD_01'] == 'L':
            df_filtrado.at[idx, 'NM_COVA'] = anterior['NM_COVA']  # Mantém NM_COVA igual ao anterior
            df_filtrado.at[idx, 'CD_01'] = 'L'  # Mantém CD_01 como 'L'
        elif atual['CD_01'] == 'N' and anterior['CD_01'] == 'L':
            df_filtrado.at[idx, 'NM_COVA'] = anterior['NM_COVA']  # Mantém NM_COVA igual ao anterior
            df_filtrado.at[idx, 'CD_01'] = 'N'  # Atualiza CD_01 para 'N'
        elif atual['CD_01'] == 'L' and not anterior['CD_01'] == 'N':
            df_filtrado.at[idx, 'CD_01'] = 'N'  # Atualiza CD_01 para 'N'
    
    # Se NM_COVA é 'N' (não L), incrementa o contador
    if atual['CD_01'] == 'N':
        df_filtrado.at[idx, 'NM_COVA'] = df_filtrado.at[idx - 1, 'NM_COVA'] + 1
    elif atual['NM_COVA'] == 0:
        print(f"Erro: 'NM_COVA' igual a 0 na linha {idx} do arquivo '{path}'.")