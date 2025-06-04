 dup_cols <- c("CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_FILA","NM_COVA","NM_FUSTE","NM_ALTURA")
                                df_final <- df_final %>%
                                  mutate(
                                    check_dup = if_else(
                                      duplicated(across(all_of(dup_cols))) |
                                        duplicated(across(all_of(dup_cols)), fromLast = TRUE),
                                      "VERIFICAR","OK"
                                    ),
                                    check_cd = case_when(
                                      CD_01 %in% LETTERS[1:24] & NM_FUSTE == "1" ~ "OK",
                                      CD_01 == "L"      & NM_FUSTE == "1" ~ "VERIFICAR",
                                      TRUE ~ "OK"
                                    ),
                                    CD_TALHAO = str_sub(as.character(CD_TALHAO), -3) %>%
                                      str_pad(width = 3, pad = "0")
                                  )
                                
                                # 6) validação da sequência de covas (L e N)
                                seq_valida <- function(df) {
                                  last <- NA_real_
                                  ok <- TRUE
                                  for (i in seq_len(nrow(df))) {
                                    cov <- df$NM_COVA[i]
                                    tipo <- df$CD_01[i]
                                    if (tipo == "L") {
                                      if (is.na(last)) last <- cov
                                      if (!is.na(cov) && cov != last) ok <- FALSE
                                    }
                                    if (tipo == "N") {
                                      if (is.na(last) || is.na(cov) || cov != last + 1) ok <- FALSE
                                      last <- cov
                                    }
                                  }
                                  ok
                                }
                                
                                df_final <- df_final %>%
                                  arrange(NM_FILA) %>%
                                  mutate(
                                    check_sqc    = "OK",
                                    NM_COVA_ORIG = NM_COVA,
                                    group_id     = cumsum(NM_FILA != lag(NM_FILA, default = first(NM_FILA)))
                                  )
                                
                                bif <- any(!map_lgl(group_split(df_final, NM_FILA), seq_valida))
                                
                                if (bif) {
                                  df_final <- df_final %>%
                                    group_by(group_id) %>%
                                    mutate(
                                      new_seq = {
                                        seqs <- seq_len(n())
                                        for (i in seq_along(seqs)) {
                                          if (CD_01[i] == "L") {
                                            ori <- NM_COVA_ORIG[i]
                                            if (i > 1 && ori == NM_COVA_ORIG[i - 1]) {
                                              seqs[i] <- seqs[i - 1]
                                              check_sqc[i] <<- "VERIFICAR"
                                            } else if (i < n() && ori == NM_COVA_ORIG[i + 1]) {
                                              seqs[i] <- seqs[i + 1]
                                              check_sqc[i] <<- "VERIFICAR"
                                            }
                                          }
                                        }
                                        seqs
                                      },
                                      NM_COVA = new_seq
                                    ) %>%
                                    ungroup() %>%
                                    select(-new_seq)
                                } else {
                                  df_final <- df_final %>%
                                    arrange(NM_FILA, NM_COVA) %>%
                                    mutate(
                                      check_sqc = if_else(
                                        CD_01 == "N" & lag(CD_01) == "L" &
                                          lag(NM_FUSTE) == "2" & NM_COVA == lag(NM_COVA),
                                        "VERIFICAR", "OK"
                                      )
                                    )
                                }
                                
                                df_final <- df_final %>% select(-NM_COVA_ORIG, -group_id)
                                qtd_ver <- sum(df_final$check_sqc == "VERIFICAR", na.rm = TRUE)
                                message("Quantidade de 'VERIFICAR': ", qtd_ver)
                                if (qtd_ver > 0) {
                                  resp <- tolower(readline("Deseja verificar agora? (s/n): "))
                                  if (resp == "s") {
                                    nome_base <- glue("IFQ6_{nome_mes}_{data_emissao}")
                                    cnt <- 1
                                    repeat {
                                      out <- file.path(pasta_output,
                                                       glue("{nome_base}_{str_pad(cnt, width = 2, pad = '0')}.xlsx"))
                                      if (!file.exists(out)) break
                                      cnt <- cnt + 1
                                    }
                                    write.xlsx(df_final, out, rowNames = FALSE)
                                    message("Dados verificados e salvos em '", out, "'.")
                                    return(invisible(NULL))
                                  }
                                }
