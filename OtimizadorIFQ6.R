# ... depois do pivot_wider() e definição de num_cols ...

# 1) "Desembrulha" listas e converte em numeric
df_pivot <- df_pivot %>%
  mutate(across(all_of(num_cols), ~ as.numeric(unlist(.x))))

# 2) Checagem opcional dos tipos
print(sapply(df_pivot[num_cols], class))  # deve mostrar "numeric"

# 3) Eleva ao cubo
df_D_wide <- df_pivot %>%
  mutate(across(all_of(num_cols), ~ .x^3))
