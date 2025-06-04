df_C <- bind_cols(df_pivot, df_metrics_C) %>%
  left_join(
    conts,
    by = c("CD_PROJETO" = "CD_PROJETO",
           "CD_TALHAO"   = "CD_TALHAO",
           "NM_PARCELA"  = "NM_PARCELA")
  ) 

# Substituindo NAs manualmente
for (col in c(falt_c, falt_f)) {
  if (col %in% names(df_C)) {
    df_C[[col]] <- replace_na(df_C[[col]], 0)
  }
}