if 'NM_FILA' in df_filtrado.columns:
    df_filtrado.loc[:, 'NM_COVA'] = df_filtrado.groupby('NM_FILA').cumcount() + 1
    print(f"Contagem de 'NM_FILA' registrada em 'NM_COVA' para o arquivo '{path}'.")
else:
    print(f"A coluna 'NM_FILA' não foi encontrada no arquivo '{path}'. Não foi possível registrar a contagem em 'NM_COVA'.")