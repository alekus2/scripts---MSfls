# --- 1. Lista de códigos (incluindo 'N') ---
codes_to_count = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]

# --- 2. Para cada código, criar flag e cumsum dentro de cada parcela ---
dfs_flags = []
for code in codes_to_count:
    tmp = df_final.copy()
    # flag 1/0
    tmp[f"flag_{code}"] = (tmp["CD_01"] == code).astype(int)
    # cumsum ordenado por cova dentro de cada parcela
    tmp = (
        tmp
        .sort_values(["CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_COVA_ORDENADO"])
        .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])
        .apply(lambda g: g.assign(**{f"cum_{code}": g[f"flag_{code}"].cumsum()}))
        .reset_index(drop=True)
    )
    # manter apenas as colunas de chave + cumulação
    dfs_flags.append(
        tmp[["CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_COVA_ORDENADO", f"cum_{code}"]]
    )

# --- 3. Unir todas as flags cumulativas num só DataFrame ---
df_all_flags = dfs_flags[0]
for dfc in dfs_flags[1:]:
    df_all_flags = df_all_flags.merge(
        dfc,
        on=["CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_COVA_ORDENADO"],
        how="left"
    )

# --- 4. Pivot das flags cumulativas (cova → colunas) ---
flags_pivot = (
    df_all_flags
    .pivot_table(
        index=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
        columns="NM_COVA_ORDENADO",
        values=[f"cum_{c}" for c in codes_to_count],
        fill_value=0
    )
)
# Simplifica nomes de coluna: ('cum_A',1) → 'A_1'
flags_pivot.columns = [
    f"{col[0].replace('cum_','')}_{col[1]}"
    for col in flags_pivot.columns
]
flags_pivot = flags_pivot.reset_index()

# --- 5. Preparar para merge com df_tabela ---
flags_pivot.rename(columns={"NM_PARCELA":"nm_parcela"}, inplace=True)
key_cols = ["CD_PROJETO","CD_TALHAO","nm_parcela"]

# Merge
df_tabela = df_tabela.merge(
    flags_pivot,
    on=key_cols,
    how="left"
)

# --- 6. Extrair coluna final de cada código (último valor cumulativo) ---
for code in codes_to_count:
    # seleciona todas as colunas geradas para este código
    code_cols = [c for c in df_tabela.columns if c.startswith(f"{code}_")]
    # a coluna definitiva 'code' é o máximo entre elas (último cumsum)
    df_tabela[code] = df_tabela[code_cols].max(axis=1)
    # opcional: remover colunas intermediárias
    df_tabela.drop(columns=code_cols, inplace=True)

# --- 7. Cálculo das métricas finais ---
sobreviventes = ["A","B","D","G","I","J","K","N","O","Q","T","V","E"]
falhas        = ["M","H","F","L","S"]

# Stand (tree/ha)
df_tabela["Stand (tree/ha)"] = (
    df_tabela[sobreviventes].sum(axis=1)
  - df_tabela[falhas].sum(axis=1)
)

# %_Sobrevivência
num = df_tabela[sobreviventes].sum(axis=1) - df_tabela[["F","I","M","H","S"]].sum(axis=1)
den = df_tabela[sobreviventes].sum(axis=1)
df_tabela["%_Sobrevivência"] = (
    (num / den * 100)
    .map(lambda x: f"{x:.2f}%".replace(".",","))
)

# Pits/ha
df_tabela["Pits/ha"] = df_tabela["n"] / df_tabela["L"] * 10000 / df_tabela["nm_area_parcela"]

# CST
df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)

# Pits por sob
pct = df_tabela["%_Sobrevivência"].str.replace("%","").str.replace(",",".").astype(float)
df_tabela["Pits por sob"] = df_tabela["Stand (tree/ha)"] / pct

# Check pits
df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]
