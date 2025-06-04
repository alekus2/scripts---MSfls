df_C <- bind_cols(df_pivot, df_metrics_C) %>%
  left_join(
    conts,
    by = c("CD_PROJETO" = "CD_PROJETO",
           "CD_TALHAO"   = "CD_TALHAO",
           "NM_PARCELA"  = "NM_PARCELA")
  ) %>%
  # substitui NA em todas as colunas de 'falt_c' e 'falt_f' por zero
  mutate(across(all_of(c(falt_c, falt_f)), ~ replace_na(.x, 0))) %>%
  mutate(
    Stand_tree_ha = ((rowSums(across(all_of(codes))) -
                        rowSums(across(all_of(falhas)))) * 10000) /
      as.numeric(nm_area_parcela),
    Pits_ha       = (((n - L) * 10000) / as.numeric(nm_area_parcela)),
    # mediana de Ht_media por projeto/talhao
    mediana_ht_proj_tal = df_res %>%
      group_by(CD_PROJETO, CD_TALHAO) %>%
      summarize(med = median(Ht_media, na.rm = TRUE), .groups = "drop") %>%
      right_join(select(., CD_PROJETO, CD_TALHAO), by = c("CD_PROJETO","CD_TALHAO")) %>%
      pull(med),
    surv_dec      = (rowSums(across(all_of(codes))) -
                       rowSums(across(all_of(falhas)))) /
      rowSums(across(all_of(codes))),
    Percent_Sobrevivencia = percent(surv_dec, accuracy = 0.1, decimal.mark = ","),
    Pits_por_sob  = Stand_tree_ha / surv_dec,
    Check_pits    = Pits_por_sob - Pits_ha
  ) %>%
  select(-surv_dec)

#DF D
df_D <- bind_cols(df_D_wide, df_metrics_D) %>%
  left_join(
    conts,
    by = c("CD_PROJETO" = "CD_PROJETO",
           "CD_TALHAO"   = "CD_TALHAO",
           "NM_PARCELA"  = "NM_PARCELA")
  ) %>%
  # substitui NA em todas as colunas de 'falt_c' e 'falt_f' por zero
  mutate(across(all_of(c(falt_c, falt_f)), ~ replace_na(.x, 0))) %>%
  mutate(
    Stand_tree_ha = ((rowSums(across(all_of(codes))) -
                        rowSums(across(all_of(falhas)))) * 10000) /
      as.numeric(nm_area_parcela),
    Pits_ha       = (((n - L) * 10000) / as.numeric(nm_area_parcela)),
    surv_dec      = (rowSums(across(all_of(codes))) -
                       rowSums(across(all_of(falhas)))) /
      rowSums(across(all_of(codes))),
    Percent_Sobrevivencia = percent(surv_dec, accuracy = 0.1, decimal.mark = ","),
    Check_covas   = Stand_tree_ha / surv_dec,
    Check_pits    = Check_covas - Pits_ha,
    Check_impares_pares = if_else(n %% 2 == 0, "Par", "Impar")
  ) %>%
  select(-surv_dec)
