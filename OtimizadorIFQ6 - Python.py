# df_res e df_final já devem estar definidos, assim como cols0, codes, falhas

# 1) montar pivot e renomear colunas
df_D = df_res.pivot_table(
    index=cols0,
    columns="NM_COVA_ORDENADO",
    values="Ht média",
    aggfunc="first",
    fill_value=0
).reset_index()
df_D.columns = [str(c) if isinstance(c, int) else c for c in df_D.columns]

# 2) identificar colunas numéricas e elevar ao cubo
num_cols_D = sorted([c for c in df_D.columns if c.isdigit()], key=int)
df_D[num_cols_D] = df_D[num_cols_D] ** 3

# 3) função de métricas
def calc_metrics(row, covas):
    vals = [row[c] for c in covas]
    last = max([i for i,v in enumerate(vals) if v>0], default=-1)
    vals = vals[:last+1] if last>=0 else []
    n = len(vals)
    med = np.median(vals) if n>0 else 0.0
    tot = sum(vals)
    ordered = sorted(vals)
    meio = n//2
    le = (sum(v for v in ordered[:meio] if v<=med)
          if n%2==0 else sum(ordered[:meio]) + med/2.0)
    pv50 = (le/tot*100) if tot else 0.0
    return pd.Series({"n":n, "n/2":meio, "Mediana":med,
                      "∑Ht":tot, "∑Ht(<=Med)":le, "PV50":pv50})

# 4) aplicar métricas
metrics_D = df_D.apply(calc_metrics, axis=1, covas=num_cols_D)
df_D_resultados = pd.concat([df_D[cols0 + num_cols_D], metrics_D], axis=1)

# 5) merge de contagens de códigos
counts = (
    df_final
    .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"]
    .value_counts()
    .unstack(fill_value=0)
    .reindex(columns=codes, fill_value=0)
    .reset_index()
)
df_D_resultados = df_D_resultados.merge(
    counts,
    left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
    right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
    how="left"
).fillna(0)

# 6) Stand (trees/ha)
df_D_resultados["Stand (tree/ha)"] = (
    df_D_resultados[codes].sum(axis=1)
    - df_D_resultados[falhas].sum(axis=1)
) * 10000 / df_D_resultados["nm_area_parcela"].astype(float)

# 7) % Sobrevivência seguro
tot_D   = df_D_resultados[codes].sum(axis=1)
valid_D = tot_D - df_D_resultados[falhas].sum(axis=1)
surv_frac_D = np.divide(valid_D, tot_D,
                        out=np.zeros_like(valid_D, dtype=float),
                        where=tot_D!=0)
df_D_resultados["%_Sobrevivência_decimal"] = surv_frac_D
df_D_resultados["%_Sobrevivência"] = (
    np.round(surv_frac_D*100,1)
      .astype(str)
      .str.replace(r"\.", ",", regex=True)
    + "%"
)

# 8) Pits/ha e checks
df_D_resultados["Pits/ha"] = (
    (df_D_resultados["n"] - df_D_resultados["L"]) * 10000
    / df_D_resultados["nm_area_parcela"].astype(float)
).fillna(0)
df_D_resultados["CHECK impares/pares"] = df_D_resultados["n"].apply(
    lambda x: "Par" if x%2==0 else "Impar"
)
df_D_resultados["%_K"] = (
    df_D_resultados["K"] /
    (df_D_resultados["n"] - df_D_resultados["L"])
).map(lambda x: f"{x:.1%}".replace(".",","))
df_D_resultados["%_L"] = (
    (df_D_resultados["H"] + df_D_resultados["I"]) /
    (df_D_resultados["n"] - df_D_resultados["L"])
).map(lambda x: f"{x:.1%}".replace(".",","))

# 9) Média Ht por talhão
medianas = (
    df_final
    .groupby(["CD_PROJETO","CD_TALHAO"])["Ht média"]
    .median()
    .reset_index(name="Média Ht")
)
df_D_resultados = df_D_resultados.merge(
    medianas,
    on=["CD_PROJETO","CD_TALHAO"],
    how="left"
)
