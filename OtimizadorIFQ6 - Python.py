# ——— monta o pivot base ———
# df_res já foi gerado e contém "Área (ha)", "Chave_stand_1", "CD_PROJETO",
# "CD_TALHAO", "nm_parcela", "nm_area_parcela" e "Ht média"

cols0 = ["Área (ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"]
df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)

df_pivot = df_res.pivot_table(
    index=cols0,
    columns="NM_COVA_ORDENADO",
    values="Ht média",
    aggfunc="first",
    fill_value=0
).reset_index()

# converte nomes de colunas inteiras para strings
df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=int)

# ——— C_tabela_resultados ———
df_tabela = df_pivot[cols0 + num_cols].copy()

def calc_metrics(row, covas):
    vals = [row[c] for c in covas]
    # ignora zeros finais
    last = max([i for i,v in enumerate(vals) if v>0], default=-1)
    vals = vals[:last+1] if last>=0 else []
    n = len(vals)
    med = np.median(vals) if n>0 else 0.0
    tot = sum(vals)
    ordered = sorted(vals)
    meio = n//2
    if n%2==0:
        le = sum(v for v in ordered[:meio] if v<=med)
    else:
        le = sum(ordered[:meio]) + med/2.0
    pv50 = (le/tot*100) if tot else 0.0
    return pd.Series({"n":n, "n/2":meio, "Mediana":med, "∑Ht":tot, "∑Ht(<=Med)":le, "PV50":pv50})

metrics_C = df_tabela.apply(calc_metrics, axis=1, covas=num_cols)
df_tabela = pd.concat([df_tabela, metrics_C], axis=1)
df_tabela["PV50"] = df_tabela["PV50"].map(lambda x: f"{x:.2f}%".replace(".",","))

# contagens por código e falhas
codes = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
falhas = ["M","H","F","L","S"]
counts = (
    df_final
    .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"]
    .value_counts()
    .unstack(fill_value=0)
    .reindex(columns=codes, fill_value=0)
    .reset_index()
)
df_tabela = df_tabela.merge(
    counts,
    left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
    right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
    how="left"
).fillna(0)

# Stand, sobrevivência, pits
df_tabela["Stand (tree/ha)"] = (
    df_tabela[codes].sum(axis=1) - df_tabela[falhas].sum(axis=1)
) * 10000 / df_tabela["nm_area_parcela"].astype(float)

tot = df_tabela[codes].sum(axis=1)
valid = tot - df_tabela[falhas].sum(axis=1)
df_tabela["%_Sobrevivência"] = (
    (valid/tot*100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
)

df_tabela["Pits/ha"] = (
    (df_tabela["n"] - df_tabela["L"]) * 10000
    / df_tabela["nm_area_parcela"].astype(float)
).fillna(0)

df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)

pct = df_tabela["%_Sobrevivência"].str.rstrip("%").str.replace(",",".").astype(float)/100
df_tabela["Pits por sob"] = df_tabela["Stand (tree/ha)"] / pct
df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]

# salva C
with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:
    df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)

# ——— D_Tabela_Resultados_Ht3 ———
df_D = df_tabela.copy()
for c in num_cols:
    df_D[c] = df_D[c] ** 3

metrics_D = df_D.apply(calc_metrics, axis=1, covas=num_cols)
df_D = pd.concat([df_D.drop(columns=["n","n/2","Mediana","∑Ht","∑Ht(<=Med)","PV50"]), metrics_D], axis=1)
df_D["PV50"] = df_D["PV50"].map(lambda x: f"{x:.2f}%".replace(".",","))

# reusa mesmas contagens e métricas de stand/pits
df_D = df_D.merge(
    df_tabela[["CST","Stand (tree/ha)","%_Sobrevivência","Pits/ha","Pits por sob","Check pits"]],
    on="CST", how="left", suffixes=("","")
)

# salva D
with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:
    df_D.to_excel(w, sheet_name="D_Tabela_Resultados_Ht3", index=False)
