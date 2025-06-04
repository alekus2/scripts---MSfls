medianas_df <- df_res %>%
  group_by(CD_PROJETO, CD_TALHAO) %>%
  summarize(mediana_ht_proj_tal = median(Ht_media, na.rm = TRUE), .groups = "drop")

df_C <- df_C %>%
  left_join(medianas_df, by = c("CD_PROJETO", "CD_TALHAO"))
