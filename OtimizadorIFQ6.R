df_final <- df_final %>%
  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
  arrange(HT_MEDIA, .by_group = TRUE) %>%  # ordenar pela altura média
  mutate(NM_COVA_ORDENADO = row_number()) %>%
  ungroup()
