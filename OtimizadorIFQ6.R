library(R6)
library(readxl)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(lubridate)
library(openxlsx)
library(glue)
library(scales)

`%notin%` <- function(x, y) !(x %in% y)
  
OtimizadorIFQ6 <- R6Class("OtimizadorIFQ6",
                            public = list(
                              validacao = function(paths) {
                                col_esp <- c(
                                  "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
                                  "NM_LARG_PARCELA","NM_COMP_PARCELA","NM_DEC_LAR_PARCELA","NM_DEC_COM_PARCELA",
                                  "DT_INICIAL","DT_FINAL","CD_EQUIPE","NM_LATITUDE","NM_LONGITUDE","NM_ALTITUDE",
                                  "DC_MATERIAL","NM_FILA","NM_COVA","NM_FUSTE","NM_DAP_ANT","NM_ALTURA_ANT",
                                  "NM_CAP_DAP1","NM_DAP2","NM_DAP","NM_ALTURA","CD_01","CD_02","CD_03"
                                )
                                meses <- c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                                           "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")
                                mes_atual    <- month(Sys.Date())
                                nome_mes     <- meses[mes_atual]
                                data_emissao <- format(Sys.Date(), "%Y%m%d")
                                base_dir     <- dirname(paths[[1]])
                                pasta_mes    <- file.path(dirname(base_dir), nome_mes)
                                pasta_output <- file.path(pasta_mes, "output")
                                dir.create(pasta_output, recursive = TRUE, showWarnings = FALSE)
                                cadastro_path <- keep(paths,
                                                      ~ str_detect(toupper(basename(.x)), "SGF")
                                )[[1]]

                                lista_df <- list()
                                equipes   <- list()
                                for (p in paths) {
                                  if (is.null(cadastro_path) || p == cadastro_path || !file.exists(p)) next
                                  nome_arq <- basename(p)
                                  nome_up  <- toupper(nome_arq)
                                  if (str_detect(nome_up, "LEBATEC")) {
                                    base <- "lebatec"
                                  } else if (str_detect(nome_up, "BRAVORE")) {
                                    base <- "bravore"
                                  } else if (str_detect(nome_up, "PROPRIA")) {
                                    base <- "propria"
                                  } else {
                                    message("Arquivo sem equipe identificada automaticamente: ", nome_arq)
                                    escolha <- ""
                                    while (!escolha %in% c("1", "2", "3")) {
                                      escolha <- readline("Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): ")
                                    }
                                    base <- c("lebatec", "bravore", "propria")[as.integer(escolha)]
                                  }
                                  
                                  equipes[[base]] <- (equipes[[base]] %||% 0) + 1
                                  sufixo <- if (equipes[[base]] == 1) "" else sprintf("_%02d", equipes[[base]])
                                  equipe  <- paste0(base, sufixo)
                                  
                                  df <- tryCatch(
                                    read_excel(p, sheet = 1, col_types = "text"),
                                    error = function(e) NULL
                                  )
                                  if (is.null(df) || any(col_esp %notin% toupper(names(df)))) {
                                    df <- tryCatch(
                                      read_excel(p, sheet = 2, col_types = "text"),
                                      error = function(e) NULL
                                    )
                                    if (is.null(df) || any(col_esp %notin% toupper(names(df)))) next
                                  }
                                  df <- df %>%
                                    set_names(toupper(str_trim(names(.)))) %>%
                                    select(all_of(col_esp)) %>%
                                    mutate(EQUIPE = equipe)
                                  lista_df[[length(lista_df) + 1]] <- df
                                }
                                
                                if (length(lista_df) == 0) {
                                  message("Nenhum arquivo processado.")
                                  return(invisible(NULL))
                                }

                                df_final <- bind_rows(lista_df) %>%
                                  mutate(NM_COVA = as.numeric(NM_COVA),
                                         NM_FILA = as.numeric(NM_FILA)) %>%
                                  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
                                  arrange(
                                    if_else(NM_FILA %% 2 == 1, NM_COVA, -NM_COVA),
                                    .by_group = TRUE
                                  ) %>%
                                  mutate(NM_COVA = row_number()) %>%
                                  ungroup()
                                
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
                                df_final <- df_final %>%
                                  mutate(
                                    Ht_media = as.numeric(NM_ALTURA),
                                    Ht_media = replace_na(Ht_media, 0)
                                  ) %>%
                                  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
                                  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA,NM_FILA) %>% 
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
                                  mutate(across(all_of(num_cols), ~ .x^3)) #oque ele deveria fazer, aplicar ao df_D onde as colunas que vao de 1 até N maximo de nm_ordenado assim como no df_c, mas com a todos os valores de 1 até N esses valores ao cubo.
                              
