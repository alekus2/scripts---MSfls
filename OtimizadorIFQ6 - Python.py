# Cálculo bruto
pits_por_sob_real = df_tabela["Stand (tree/ha)"] / pct

# Cálculo arredondado padrão
pits_por_sob_ceiled = pits_por_sob_real.apply(math.ceil)

# Calcular Check pits inicialmente com valor ceiled
check_pits_inicial = pits_por_sob_ceiled - df_tabela["Pits/ha"]

# Aplicar a lógica condicional
df_tabela["Pits por sob"] = np.where(
    check_pits_inicial == 1, pits_por_sob_real,  # não arredonda
    np.where(
        check_pits_inicial == -1, pits_por_sob_ceiled,  # arredonda
        pits_por_sob_ceiled  # padrão
    )
)

# Recalcular o Check pits com base no valor final
df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]
