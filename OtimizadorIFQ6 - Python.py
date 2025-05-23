# --- antes: df_D_resultados["Média Ht"] = ... .values  (retiramos essa linha) ---

# 1) calcula a mediana de Ht média por projeto+talhão
medianas = (
    df_final
    .groupby(["CD_PROJETO","CD_TALHAO"])["Ht média"]
    .median()
    .reset_index(name="Média Ht")
)

# 2) faz merge para associar a mediana a cada linha de df_D_resultados
df_D_resultados = df_D_resultados.merge(
    medianas,
    on=["CD_PROJETO","CD_TALHAO"],
    how="left"
)

# (agora df_D_resultados já tem a coluna "Média Ht" corretamente alinhada)
