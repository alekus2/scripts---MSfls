df_final <- df_final %>%
  # converte para numérico só pra garantir
  mutate(NM_COVA = as.numeric(NM_COVA)) %>%
  # ordena primeiro pelos três campos-chaves
  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_COVA) %>%
  # para cada combinação de projeto+talhão+parcela,
  # numera de 1 até n
  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
  mutate(NM_COVA = row_number()) %>%
  ungroup()
