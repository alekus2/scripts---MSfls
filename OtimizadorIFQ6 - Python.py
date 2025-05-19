def ajustar_pits_por_sob(row):
    original = row["Stand (tree/ha)"] / (float(row["%_Sobrevivência"].replace(",", ".").replace("%", "")) / 100)
    check_diff = original - row["Pits/ha"]
    if abs(round(check_diff)) == 1:
        return original  # mantém valor original (com casas decimais)
    else:
        return math.floor(original)  # arredonda para baixo

df_tabela["Pits por sob"] = df_tabela.apply(ajustar_pits_por_sob, axis=1)
