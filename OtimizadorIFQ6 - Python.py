# Garantir que as chaves estejam padronizadas
df_aux = df_final[["CD_PROJETO", "CD_TALHAO", "DC_MATERIAL", "DT_MEDIÇÃO1", "EQUIPE_2"]].drop_duplicates()

# Mesclar com df_D_resultados pelas chaves
df_D_resultados = df_D_resultados.merge(
    df_aux,
    on=["CD_PROJETO", "CD_TALHAO"],
    how="left"
)

# Renomear colunas conforme desejado
df_D_resultados.rename(columns={
    "DC_MATERIAL": "Material Genético",
    "DT_MEDIÇÃO1": "Data Medição",
    "EQUIPE_2": "Equipe"
}, inplace=True)
