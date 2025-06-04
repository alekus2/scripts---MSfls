df_C <- bind_cols(df_pivot, df_metrics_C) %>%
                                  left_join(
                                    conts,
                                    by = c("CD_PROJETO" = "CD_PROJETO",
                                           "CD_TALHAO"   = "CD_TALHAO",
                                           "NM_PARCELA"  = "NM_PARCELA")
                                  ) %>%
                                  mutate(across(all_of(c(falt_c, falt_f)), ~ replace_na(.x, 0))) %>%
                                  mutate(
                                    Stand_tree_ha = ((rowSums(across(all_of(codes))) -
                                                        rowSums(across(all_of(falhas)))) * 10000) /
                                      as.numeric(NM_AREA_PARCELA),
                                    Pits_ha       = (((n - L) * 10000) / as.numeric(NM_AREA_PARCELA)),
                                    mediana_ht_proj_tal = df_res %>%
                                      group_by(CD_PROJETO, CD_TALHAO) %>%
                                      summarize(med = median(Ht_media, na.rm = TRUE), .groups = "drop") %>%
                                      right_join(select(., CD_PROJETO, CD_TALHAO, NM_PARCELA), by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
                                      pull(med),
                                    surv_dec      = (rowSums(across(all_of(codes))) -
                                                       rowSums(across(all_of(falhas)))) /
                                      rowSums(across(all_of(codes))),
                                    Percent_Sobrevivencia = percent(surv_dec, accuracy = 0.1, decimal.mark = ","),
                                    Pits_por_sob  = Stand_tree_ha / surv_dec,
                                    Check_pits    = Pits_por_sob - Pits_ha
                                  ) %>%
                                  select(-surv_dec)
Error in `mutate()`:
i In argument: `mediana_ht_proj_tal = `%>%`(...)`.
Caused by error in `select()`:
! Can't select columns that don't exist.
x Columns `1`, `2`, `1`, `2`, `1`, etc. don't exist.
Run `rlang::last_trace()` to see where the error occurred.
