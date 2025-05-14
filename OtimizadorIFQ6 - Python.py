# processa parte 2
df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
df_cadastro["Talhão_z3"] = df_cadastro["Talhão"].astype(str).str[-3:].str.zfill(3)
df_cadastro["Index"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão_z3"]

df_final["Index"] = df_final["CD_PROJETO"].astype(str).str.strip() + df_final["CD_TALHAO"].astype(str).str.strip()

area_col = next((c for c in df_cadastro.columns if "AREA" in c.upper()), None)

df_res = pd.merge(
    df_final,
    df_cadastro[["Index", area_col]],
    on="Index",
    how="left"
)

# garante que existe a coluna e preenche NaN com string vazia
df_res.rename(columns={area_col: "Área(ha)"}, inplace=True)
df_res["Área(ha)"] = df_res["Área(ha)"].fillna("")  

# renomeia as outras colunas que você precisa
df_res.rename(columns={
    "Chave_stand_1":   "Chave_stand_1",
    "NM_PARCELA":      "nm_parcela",
    "NM_AREA_PARCELA": "nm_area_parcela"
}, inplace=True)

# monta o pivot
cols0 = ["Área(ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"]
df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)
df_pivot = df_res.pivot_table(
    index=cols0,
    columns="NM_COVA_ORDENADO",
    values="Ht média",
    aggfunc="first",
    fill_value=0
).reset_index()

df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=lambda x: int(x))
df_tabela = df_pivot[cols0 + num_cols]

# grava tudo sempre
with pd.ExcelWriter(out, engine="openpyxl") as w:
    df_cadastro.drop(columns=["Talhão_z3"], inplace=True)
    df_cadastro.to_excel(w, sheet_name="Cadastro_SGF", index=False)
    df_final.to_excel(w, sheet_name=f"Dados_CST_{nome_mes}", index=False)
    df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)
