# Solução reestruturada para evitar erro com mutate()

# 1. Calcular a mediana de altura por projeto e talhão
medianas_df <- df_res %>%
  group_by(CD_PROJETO, CD_TALHAO) %>%
  summarize(mediana_ht_proj_tal = median(Ht_media, na.rm = TRUE), .groups = "drop")

# 2. Juntar os dados e calcular métricas

# unindo df_pivot com df_metrics_C

df_C <- bind_cols(df_pivot, df_metrics_C) %>%

  # adicionar contagens
  left_join(
    conts,
    by = c("CD_PROJETO" = "CD_PROJETO",
           "CD_TALHAO"   = "CD_TALHAO",
           "NM_PARCELA"  = "NM_PARCELA")
  ) %>%

  # substituir NAs por zero nas colunas falt_c e falt_f
  mutate(across(all_of(c(falt_c, falt_f)), ~ replace_na(.x, 0))) %>%

  # juntar as medianas calculadas
  left_join(medianas_df, by = c("CD_PROJETO", "CD_TALHAO")) %>%

  # calcular colunas derivadas
  mutate(
    Stand_tree_ha = ((rowSums(across(all_of(codes))) -
                        rowSums(across(all_of(falhas)))) * 10000) /
      as.numeric(NM_AREA_PARCELA),

    Pits_ha       = (((n - L) * 10000) / as.numeric(NM_AREA_PARCELA)),

    surv_dec      = (rowSums(across(all_of(codes))) -
                       rowSums(across(all_of(falhas)))) /
      rowSums(across(all_of(codes))),

    Percent_Sobrevivencia = percent(surv_dec, accuracy = 0.1, decimal.mark = ","),

    Pits_por_sob  = Stand_tree_ha / surv_dec,

    Check_pits    = Pits_por_sob - Pits_ha
  ) %>%

  select(-surv_dec)
