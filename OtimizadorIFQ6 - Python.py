# 1. Definição correta dos códigos
codes_to_count = ["A","B","D","F","G","H","I","J","L","M","O","Q","K","T","V","S","E"]

# 2. Contagem acumulada em df_tabela, usando df_final["CD_01"]
for code in codes_to_count:
    df_tabela[code] = (df_final["CD_01"] == code).cumsum()

# 3. Stand (tree/ha)
sobreviventes = ["A","B","D","G","I","J","K","O","Q","T","V","E"]
falhas        = ["M","H","F","L","S"]
df_tabela["Stand (tree/ha)"] = df_tabela[sobreviventes].sum(axis=1) - df_tabela[falhas].sum(axis=1)

# 4. %_Sobrevivência
num = df_tabela[sobreviventes].sum(axis=1) - df_tabela[["F","I","M","H","S"]].sum(axis=1)
den = df_tabela[sobreviventes].sum(axis=1)
df_tabela["%_Sobrevivência"] = (num / den * 100).map(lambda x: f"{x:.2f}%".replace(".",","))

# 5. Pits/ha
df_tabela["Pits/ha"] = df_tabela["n"] / df_tabela["L"] * 10000 / df_tabela["nm_area_parcela"]

# 6. CST
df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)

# 7. Pits por sob
# Converter %_Sobrevivência de texto para float
pct = df_tabela["%_Sobrevivência"].str.replace("%","").str.replace(",",".").astype(float)
df_tabela["Pits por sob"] = df_tabela["Stand (tree/ha)"] / pct

# 8. Check pits
df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]
