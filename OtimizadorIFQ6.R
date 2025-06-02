df_final <- bind_rows(lista_df) %>%
  mutate(NM_COVA = as.numeric(NM_COVA)) %>%
  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA, NM_COVA) %>%
  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
  mutate(
    NM_COVA_OLD = NM_COVA,
    NM_COVA     = row_number()
  ) %>%
  ungroup()
