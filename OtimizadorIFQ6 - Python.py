df_D_tabela = df_tabela.copy()
cols_cova_ordenado = [col for col in df_D_tabela.columns if col.isdigit()]
for col in cols_cova_ordenado:
    df_D_tabela[col] = df_D_tabela[col] ** 3

metrics_D = df_D_tabela.apply(_calc_row, axis=1)
df_D_tabela = pd.concat([df_D_tabela, metrics_D], axis=1)

if "PV50" in df_D_tabela.columns:
    df_D_tabela["PV50"] = df_D_tabela["PV50"].astype(str).str.replace(",", ".").str.replace("%", "")
    df_D_tabela["PV50"] = pd.to_numeric(df_D_tabela["PV50"], errors='coerce')
    df_D_tabela["PV50"] = df_D_tabela["PV50"].map(lambda x: f"{x:.2f}%".replace(".", ",") if pd.notnull(x) else "0,00%")
else:
    print("A coluna PV50 não foi encontrada em D_Tabela.")
