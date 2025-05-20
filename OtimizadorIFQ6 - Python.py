# === Bloco completo para gerar D_Tabela_Resultados_Ht3 a partir de df_tabela ===

# 1) Copia df_tabela e eleva ao cubo cada coluna de cova ordenada
df_D_tabela = df_tabela.copy()
cols_cova_ordenado = [col for col in df_D_tabela.columns if col.isdigit()]
for col in cols_cova_ordenado:
    df_D_tabela[col] = df_D_tabela[col] ** 3

# 2) Recalcula métricas básicas (n, n/2, Mediana, ∑Ht, ∑Ht(<=Med), PV50)
def _calc_row(row):
    valores = [0 if pd.isnull(row[c]) else row[c] for c in cols_cova_ordenado]
    últimos = [i for i, v in enumerate(valores) if v > 0]
    if últimos:
        fim = max(últimos)
        valores = valores[:fim+1]
    else:
        valores = []
    n = len(valores)
    meio = n // 2
    med = np.median(valores) if valores else 0.0
    soma_total = sum(valores)
    ordenados = sorted(valores)
    if n % 2 == 0:
        soma_le = sum(v for v in ordenados[:meio] if v <= med)
    else:
        soma_le = sum(ordenados[:meio]) + med/2.0
    pv50 = (soma_le / soma_total * 100.0) if soma_total else 0.0
    return pd.Series({
        "n": n,
        "n/2": meio,
        "Mediana": med,
        "∑Ht": soma_total,
        "∑Ht(<=Med)": soma_le,
        "PV50": pv50
    })

metrics_D = df_D_tabela.apply(_calc_row, axis=1)
df_D_tabela = pd.concat([df_D_tabela, metrics_D], axis=1)

# 3) Formata a coluna PV50 para usar vírgula e '%' 
if "PV50" in df_D_tabela.columns:
    df_D_tabela["PV50"] = (
        df_D_tabela["PV50"].astype(str)
                        .str.replace(",", ".")
                        .str.replace("%", "")
                        .astype(float)
                        .map(lambda x: f"{x:.2f}%".replace(".", ",") if pd.notnull(x) else "0,00%")
    )
else:
    print("A coluna PV50 não foi encontrada em D_Tabela.")

# 4) Conta códigos por parcela (A, B, D, …) e identifica falhas (M, H, F, L, S)
counts = (
    df_final
    .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"]
    .value_counts()
    .unstack(fill_value=0)
)
codes_to_count = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
falhas = ["M","H","F","L","S"]
counts = counts.reindex(columns=codes_to_count, fill_value=0).reset_index()

# 5) Mescla as contagens no df_D_tabela
df_D_tabela = df_D_tabela.merge(
    counts,
    left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
    right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
    how="left"
).fillna(0)

# 6) Calcula Stand (tree/ha)
df_D_tabela["Stand (tree/ha)"] = (
    df_D_tabela[codes_to_count].sum(axis=1)
    - df_D_tabela[falhas].sum(axis=1)
) * 10000 / df_D_tabela["nm_area_parcela"].astype(float)

# 7) Calcula % Sobrevivência
total = df_D_tabela[codes_to_count].sum(axis=1)
valid = total - df_D_tabela[falhas].sum(axis=1)
df_D_tabela["%_Sobrevivência"] = (
    (valid / total * 100).round(1)
    .map(lambda x: f"{x:.1f}%".replace(".",","))
)

# 8) Calcula Pits/ha
df_D_tabela["Pits/ha"] = (
    (df_D_tabela["n"] - df_D_tabela["L"])
    * 10000 / df_D_tabela["nm_area_parcela"].astype(float)
).fillna(0)

# 9) Gera identificador CST
df_D_tabela["CST"] = (
    df_D_tabela["CD_TALHAO"].astype(str)
    + "-" 
    + df_D_tabela["nm_parcela"].astype(str)
)

# 10) Calcula Pits por sob
pct = (
    df_D_tabela["%_Sobrevivência"]
    .str.replace("%","")
    .str.replace(",",".")
    .astype(float)
    / 100
)
df_D_tabela["Pits por sob"] = (
    df_D_tabela["Stand (tree/ha)"] / pct
)

# 11) Check pits (diferença entre Pits por sob e Pits/ha)
df_D_tabela["Check pits"] = df_D_tabela["Pits por sob"] - df_D_tabela["Pits/ha"]

# 12) Salva no Excel na aba "D_Tabela_Resultados_Ht3"
with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:
    df_D_tabela.to_excel(w, sheet_name="D_Tabela_Resultados_Ht3", index=False)
