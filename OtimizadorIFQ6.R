
                                #PARTE 2
                                
                                df_final <- df_final %>%
                                  mutate(
                                    Ht_media = as.numeric(NM_ALTURA),
                                    Ht_media = replace_na(Ht_media, 0)
                                  ) %>%
                                  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, Ht_media) %>%
                                  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
                                  mutate(NM_COVA_ORDENADO = row_number()) %>%
                                  ungroup() %>%
                                  mutate(
                                    Chave_stand_1 = paste(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
                                    DT_MEDICAO1  = DT_INICIAL,
                                    EQUIPE_2     = CD_EQUIPE
                                  ) %>%
                                  select(-check_dup, -check_cd, -check_sqc)
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
                                  stop("A coluna de área não foi encontrada em df_cadastro.")
                                }
                                cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
                                           "NM_PARCELA", "NM_AREA_PARCELA")
                                df_pivot <- df_res %>%
                                  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>%
                                  pivot_wider(
                                    names_from  = NM_COVA_ORDENADO,
                                    values_from = Ht_media,
                                    values_fill = 0
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
                                df_D_wide <- df_pivot %>%
                                  mutate(across(all_of(num_cols), ~ .x^3))
                                metrics_list_D <- lapply(seq_len(nrow(df_D_wide)), function(i) {
                                  calc_metrics(df_D_wide[i, num_cols])
                                })
                                df_metrics_D <- bind_rows(metrics_list_D)
                                df_D <- bind_cols(df_D_wide, df_metrics_D) %>%
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
                                    surv_dec      = (rowSums(across(all_of(codes))) -
                                                       rowSums(across(all_of(falhas)))) /
                                      rowSums(across(all_of(codes))),
                                    Percent_Sobrevivencia = percent(surv_dec, accuracy = 0.1, decimal.mark = ","),
                                    Check_covas   = Stand_tree_ha / surv_dec,
                                    Check_pits    = Check_covas - Pits_ha,
                                    Check_impares_pares = if_else(n %% 2 == 0, "Par", "Impar")
                                  ) %>%
                                  select(-surv_dec)
                                df_aux <- df_final %>%
                                  select(CD_PROJETO, CD_TALHAO, DC_MATERIAL, DT_MEDICAO1, EQUIPE_2) %>%
                                  distinct()
                                df_D <- df_D %>%
                                  left_join(df_aux, by = c("CD_PROJETO", "CD_TALHAO")) %>%
                                  rename(
                                    Material_Genetico = DC_MATERIAL,
                                    Data_Medicao      = DT_MEDICAO1,
                                    Equipe            = EQUIPE_2
                                  )
                                df_D <- df_D %>%
                                  mutate(
                                    Percent_K = if_else(
                                      (n - L) > 0,
                                      paste0(round((K / (n - L)) * 100, 1), "%"),
                                      "0%"
                                    ),
                                    Percent_L = if_else(
                                      (n - L) > 0,
                                      paste0(round(((H + I) / (n - L)) * 100, 1), "%"),
                                      "0%"
                                    )
                                  )
                                nome_base2 <- glue("BASE_IFQ6_{nome_mes}_{data_emissao}")
                                cnt2 <- 1
                                repeat {
                                  out2 <- file.path(pasta_output,
                                                    glue("{nome_base2}_{str_pad(cnt2, width = 2, pad = '0')}.xlsx"))
                                  if (!file.exists(out2)) break
                                  cnt2 <- cnt2 + 1
                                }
                                wb <- createWorkbook()
                                addWorksheet(wb, "Cadastro_SGF")
                                writeData(wb, "Cadastro_SGF", df_cadastro %>% select(-Index))
                                addWorksheet(wb, glue("Dados_CST_{nome_mes}"))
                                writeData(wb, glue("Dados_CST_{nome_mes}"), df_final %>% select(-Index))
                                addWorksheet(wb, "C_tabela_resultados")
                                writeData(wb, "C_tabela_resultados", df_C)
                                addWorksheet(wb, "D_tabela_resultados_Ht3")
                                writeData(wb, "D_tabela_resultados_Ht3", df_D)
                                saveWorkbook(wb, out2, overwrite = TRUE)
                                message("Tudo gravado em '", out2, "'")
                              }
                            )
  )
  pasta_dados <- "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at"
  arquivos <- list.files(
    path       = pasta_dados,
    pattern    = "\\.xlsx$",
    full.names = TRUE,
    recursive = TRUE
  )
  arquivos <- c(
    arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
    setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)), "SGF")])
  )
  print(arquivos)
  otimizador <- OtimizadorIFQ6$new()
  otimizador$validacao(arquivos)

Error in `mutate()`:
i In argument: `mediana_ht_proj_tal = `%>%`(...)`.
Caused by error:
! `mediana_ht_proj_tal` must be size 324 or 1, not 59.
Run `rlang::last_trace()` to see where the error occurred.
