df_final['equipe_2'] = df_final['EQUIPE']
df_final['Dt_medição'] = df_final['DT_INICIAL']
df_final['chave_2'] = (
    df_final['CD_PROJETO'].astype(str) + '-' +
    df_final['CD_TALHAO'].astype(str) + '-' +
    df_final['NM_PARCELA'].astype(str)
)
df_final['Ht_média'] = df_final['ht média'].apply(lambda x: f"{x:.1f}".replace('.',','))
df_final = df_final.sort_values(
    by=['CD_PROJETO','CD_TALHAO','NM_PARCELA','nm_cova_ordenado']
)
df_final = df_final[['equipe_2','Dt_medição','chave_2','nm_cova_ordenado','Ht_média']]
