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
                                print(df_final$Index)
                                print(df_cadastro$Index)
                                
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

                                cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
                                           "NM_PARCELA", "NM_AREA_PARCELA")

                                df_pivot <- df_res %>%
                                  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>% #da erro de Can't convert `fill` <double> to <list>.
                                  pivot_wider(
                                    names_from  = NM_COVA_ORDENADO,
                                    values_from = Ht_media,
                                    values_fill = list(Ht_media = 0) 
                                  )
                                num_cols <- df_pivot %>%
                                  select(-all_of(cols0)) %>%
                                  names()
                                #####################
essa é metade do codigo que estou desenvolvendo em que trava nessa parte.      
