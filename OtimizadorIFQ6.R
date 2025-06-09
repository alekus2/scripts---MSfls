df_cadastro <- read_excel(cadastro_path, sheet = 1, col_types = "text") %>%
                                  mutate(Index = paste0(`Id Projeto`, Talhão))
                                
                                df_final <- df_final %>%
                                  mutate(
                                    Index = paste0(CD_PROJETO, CD_TALHAO),
                                    Index = if_else(
                                      str_detect(Index, "-\\d{2}$"),
                                      Index,
                                      if_else(
                                        str_detect(Index, "-\\d$"),
                                        str_replace(Index, "-(\\d)$", "-0\\1"),
                                        paste0(Index, "-01")
                                      )
                                    )
                                  )
                                area_col <- df_cadastro %>% select(contains("ÁREA")) %>% names() %>% first()

                                if (!is.null(area_col) && area_col %in% names(df_cadastro)) {
                                  df_res <- df_final %>%
                                    left_join(
                                      df_cadastro %>% select(Index, !!sym(area_col)),
                                      by = "Index"
                                    ) %>%
                                    rename(Area_ha = !!sym(area_col)) %>% 
                                    mutate(Area_ha = replace_na(Area_ha, 0)) 
                                } else {
                                  stop("A coluna de Área não foi encontrada em df_cadastro.")
                                }
                                
                                df_res <- df_res %>%
                                  mutate(Ht_media = as.numeric(Ht_media))  
                                
                                print(str(df_res$Ht_media))
                                
                                cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
                                           "NM_PARCELA", "NM_AREA_PARCELA")
                                
                                df_pivot <- df_res %>%
                                  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>%
                                  pivot_wider(
                                    names_from  = NM_COVA_ORDENADO,
                                    values_from = Ht_media
                                  )
          
                                num_cols <- df_pivot %>%
                                  select(-all_of(cols0)) %>%
                                  names()
                                
                                codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
                                falhas <- c("M","H","F","L","S")

                                calc_metrics <- function(vals) {
                                  vals_num <- as.numeric(vals)
                                  last_pos <- max(which(vals_num > 0), na.rm = TRUE)
                                  if (is.infinite(last_pos)) last_pos <- 0
                                  sub_vals <- if (last_pos > 0) vals_num[1:last_pos] else numeric(0)
                                  n    <- length(sub_vals)
                                  med  <- if (n > 0) median(sub_vals) else 0
                                  tot  <- sum(sub_vals)
                                  ordv <- sort(sub_vals)
                                  meio <- floor(n / 2)
                                  le   <- if (n == 0) {
                                    0
                                  } else if (n %% 2 == 0) {
                                    sum(ordv[1:meio][ordv[1:meio] <= med])
                                  } else {
                                    sum(ordv[1:meio]) + med / 2
                                  }
                                  pv50 <- if (tot > 0) (le / tot) * 100 else 0
                                  tibble(
                                    n = n,
                                    metade_n = meio,
                                    mediana = med,
                                    soma_ht = tot,
                                    soma_ht_le_med = le,
                                    pv50 = pv50
                                  )
                                }

                                metrics_list_C <- lapply(seq_len(nrow(df_pivot)), function(i) {
                                  calc_metrics(df_pivot[i, num_cols])
                                })
                                df_metrics_C <- bind_rows(metrics_list_C)

                                conts <- df_res %>%
                                  count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
                                  pivot_wider(
                                    names_from  = CD_01,
                                    values_from = n,
                                    values_fill = list(.default = 0)
                                  )
                                falt_c <- setdiff(codes, names(conts))
                                if (length(falt_c) > 0) conts[falt_c] <- 0
                                falt_f <- setdiff(falhas, names(conts))
                                if (length(falt_f) > 0) conts[falt_f] <- 0
                                
                                medianas_df <- df_res %>%
                                  group_by(CD_PROJETO, CD_TALHAO) %>%
                                  summarize(mediana_ht_proj_tal = median(Ht_media, na.rm = TRUE), .groups = "drop")
                                df_C <- bind_cols(df_pivot, df_metrics_C) %>%
                                  left_join(
                                    conts,
                                    by = c("CD_PROJETO" = "CD_PROJETO",
                                           "CD_TALHAO"   = "CD_TALHAO",
                                           "NM_PARCELA"  = "NM_PARCELA")
                                  ) %>%
                                  mutate(across(all_of(c(falt_c, falt_f)), ~ replace_na(.x, 0))) %>%
                                  left_join(medianas_df, by = c("CD_PROJETO", "CD_TALHAO")) %>%
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

                                df_D_wide <- df_pivot %>%
                                  mutate(across(all_of(num_cols), ~ .x^3))


output:
Error in `mutate()`:
i In argument: `across(all_of(num_cols), ~.x^3)`.
Caused by error in `across()`:
! Can't compute column `1`.
Caused by error in `` `1`^3 ``:
! argumento não-numérico para operador binário
Run `rlang::last_trace()` to see where the error occurred.
