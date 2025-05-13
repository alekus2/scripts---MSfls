df_final = df_final.sort_values(by=['CD_PROJETO','CD_TALHAO','NM_PARCELA','NM_ALTURA'])
df_final['nm_cova_ordenado'] = df_final.groupby(['CD_PROJETO','CD_TALHAO','NM_PARCELA']).cumcount() + 1
df_final = df_final.sort_values(by=['CD_PROJETO','CD_TALHAO','NM_PARCELA','nm_cova_ordenado'])
df_final.drop(columns=['check dup','check cd','check SQC'], inplace=True)
