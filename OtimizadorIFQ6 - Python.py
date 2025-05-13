df_final['ht média'] = df_final['NM_ALTURA'].fillna(0)
df_final = df_final.sort_values(
    by=['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA', 'ht média']
)
df_final['NM_COVA_ORDENADO'] = (
    df_final
      .groupby(['CD_PROJETO', 'CD_TALHAO', 'NM_PARCELA'])
      .cumcount() + 1
)
df_final['Ht_média'] = df_final['ht média'].apply(lambda x: f"{x:.1f}".replace('.',','))
