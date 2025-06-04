  
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
                                # 1) colunas esperadas
                                col_esp <- c(
                                  "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
                                  "NM_LARG_PARCELA","NM_COMP_PARCELA","NM_DEC_LAR_PARCELA","NM_DEC_COM_PARCELA",
                                  "DT_INICIAL","DT_FINAL","CD_EQUIPE","NM_LATITUDE","NM_LONGITUDE","NM_ALTITUDE",
                                  "DC_MATERIAL","NM_FILA","NM_COVA","NM_FUSTE","NM_DAP_ANT","NM_ALTURA_ANT",
                                  "NM_CAP_DAP1","NM_DAP2","NM_DAP","NM_ALTURA","CD_01","CD_02","CD_03"
                                )
                                
                                # 2) datas e diretórios
                                meses <- c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                                           "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")
                                mes_atual    <- month(Sys.Date())
                                nome_mes     <- meses[mes_atual]
                                data_emissao <- format(Sys.Date(), "%Y%m%d")
                                base_dir     <- dirname(paths[[1]])
                                pasta_mes    <- file.path(dirname(base_dir), nome_mes)
                                pasta_output <- file.path(pasta_mes, "output")
                                dir.create(pasta_output, recursive = TRUE, showWarnings = FALSE)
                                
                                # 3) identifica arquivo de cadastro (SGF)
                                cadastro_path <- keep(paths,
                                                      ~ str_detect(toupper(basename(.x)), "SGF")
                                )[[1]]
                                
                                # 4) leitura dos arquivos de medição e atribuição de equipe
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
                                
                                # 5) concatenação e verificações iniciais
                                df_final <- bind_rows(lista_df) %>%
                                  mutate(NM_COVA = as.numeric(NM_COVA)) %>%
                                  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA, NM_COVA) %>%
                                  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
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
                                
                                # 7) preparar Ht_media e ordenação conforme Python
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
                                
                                # 8) leitura de cadastro e criação de “Index”
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
                                
                                area_col <- df_cadastro %>% select(contains("AREA")) %>% names() %>% first()
                                df_res <- df_final %>%
                                  left_join(
                                    df_cadastro %>% select(Index, all_of(area_col)),
                                    by = "Index" #deu erro aqui vey, pelo oque parece o select nao está encontrando os indexs que batem em cadastro e em final
                                  ) %>%
                                  rename(Area_ha = !!sym(area_col)) %>%
                                  mutate(Area_ha = replace_na(Area_ha, "")) %>%
                                  rename(
                                    nm_parcela      = NM_PARCELA,
                                    nm_area_parcela = NM_AREA_PARCELA
                                  )
                                
                                # 9) Construção da tabela C conforme lógica do Python
                                cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
                                           "nm_parcela", "nm_area_parcela")

                                df_pivot <- df_res %>%
                                  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>%
                                  pivot_wider(
                                    names_from  = NM_COVA_ORDENADO,
                                    values_from = Ht_media,
                                    values_fill = 0
                                  )
                                if (anyNA(df_pivot[cols0])) {
                                  stop("Existem valores ausentes nas colunas necessárias para a operação.")
                                }
                                
                                # identificar colunas numéricas (os nomes são caracteres, mas representam posições)
                                num_cols <- df_pivot %>%
                                  select(-all_of(cols0)) %>%
                                  names()
                                
                                codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
                                falhas <- c("M","H","F","L","S")
                                
                                # função para métricas (vetor de valores)
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
                                
                                # aplicar calc_metrics linha a linha
                                metrics_list_C <- lapply(seq_len(nrow(df_pivot)), function(i) {
                                  calc_metrics(df_pivot[i, num_cols])
                                })
                                df_metrics_C <- bind_rows(metrics_list_C)
                                
                                # contagem de códigos por grupo
                                conts <- df_res %>%
                                  count(CD_PROJETO, CD_TALHAO, nm_parcela, CD_01) %>%
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
                                           "nm_parcela"  = "nm_parcela")
                                  ) %>%
                                  replace_na(list_across(all_of(c(falt_c, falt_f)), 0)) %>%
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
                                
                                # 10) Construção da tabela D (Ht^3)
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
                                           "nm_parcela"  = "nm_parcela")
                                  ) %>%
                                  replace_na(list_across(all_of(c(falt_c, falt_f)), 0)) %>%
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
                                
                                # 11) adicionar Material_Genetico, Data_Medicao e Equipe na tabela D
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
                                
                                # 12) percentuais K e L na tabela D
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
                                
                                # 13) gravação final em Excel
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

Error in `select()`:
! Selections can't have missing values.
Run `rlang::last_trace()` to see where the error occurred.
