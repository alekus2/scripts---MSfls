df_all <- df_all %>%
  arrange(NM_FILA) %>%
  group_by(NM_FILA) %>%
  mutate(
    idx = row_number(),
    new_cova = {
      # seu código de lógica aqui...
    }
  ) %>%
  ungroup() %>%
  # sobrescreve a coluna NM_COVA com new_cova
  mutate(NM_COVA = new_cova) %>%
  # remove as colunas temporárias
  select(-idx, -new_cova)
