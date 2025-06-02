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
      nomes_colunas <- c(
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
      # 3) arquivo cadastro
      cadastro_path <- keep(paths,
                            ~ str_detect(toupper(basename(.x)), "SGF")
      )[[1]]
      # 4) leitura e atribuição de equipe
      lista_df <- list()
      equipes   <- list()
      for (p in paths) {
        if (is.null(cadastro_path) || p == cadastro_path || !file.exists(p)) next
        nome_arquivo <- basename(p)
        if (str_detect(nome_arquivo, regex("lebatec", ignore_case = TRUE))) {
          base <- "lebatec"
        } else if (str_detect(nome_arquivo, regex("bravore", ignore_case = TRUE))) {
          base <- "bravore"
        } else if (str_detect(nome_arquivo, regex("propria", ignore_case = TRUE))) {
          base <- "propria"
        } else {
          message("Arquivo sem equipe identificada automaticamente: ", nome_arquivo)
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
        if (is.null(df) || any(nomes_colunas %notin% toupper(names(df)))) {
          df <- tryCatch(
            read_excel(p, sheet = 2, col_types = "text"),
            error = function(e) NULL
          )
          if (is.null(df) || any(nomes_colunas %notin% toupper(names(df)))) next
        }
        df <- df %>%
          set_names(toupper(str_trim(names(.)))) %>%
          select(all_of(nomes_colunas)) %>%
          mutate(EQUIPE = equipe)
        lista_df[[length(lista_df) + 1]] <- df
      }
      if (length(lista_df) == 0) {
        message("Nenhum arquivo processado.")
        return(invisible(NULL))
      }
      # 5) concatenação e verificações
      df_final <- bind_rows(lista_df) %>%
        mutate(NM_COVA = as.numeric(NM_COVA)) %>%
        arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA, NM_COVA) %>%
        group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
        mutate(
          NM_COVA = row_number()
        ) %>%
        ungroup()
      
      dup_cols <- c("CD_PROJETO","CD_TALHAO","NM_PARCELA",
                    "NM_FILA","NM_COVA","NM_FUSTE","NM_ALTURA")
      df_final <- df_final %>%
        mutate(
          check_dup = if_else(
            duplicated(across(all_of(dup_cols))) |
              duplicated(across(all_of(dup_cols)), fromLast = TRUE),
            "VERIFICAR","OK"
          ),
          check_cd = case_when(
            CD_01 %in% LETTERS[1:24] & NM_FUSTE == "1" ~ "OK",
            CD_01 == "L" & NM_FUSTE == "1"           ~ "VERIFICAR",
            TRUE                                     ~ "OK"
          ),
          CD_TALHAO = str_sub(as.character(CD_TALHAO), -3) %>%
            str_pad(width = 3, pad = "0")
        )
      
      # 6) sequencia
      seq_valida <- function(df) {
        df <- df %>%
          mutate(NM_COVA = as.numeric(NM_COVA)) 
        
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
        mutate(NM_COVA = as.numeric(NM_COVA)) %>%  
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
                  if (i > 1 && ori == NM_COVA_ORIG[i - 1]) seqs[i] <- seqs[i - 1]
                  else if (i < n() && ori == NM_COVA_ORIG[i + 1]) seqs[i] <- seqs[i + 1]
                }
              }
              seqs
            },
            check_sqc = if_else(row_number() != new_seq, "VERIFICAR", "OK"),
            NM_COVA   = new_seq
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
      
      # 7) opcional salvar ver
      qtd_ver <- sum(df_final$check_sqc == "VERIFICAR")
      message("Quantidade de VERIFICAR: ", qtd_ver)
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
          message("Dados salvos em ", out)
          return(invisible(NULL))
        }
      }
      # 8) gera tabelas C e D
      df_final <- df_final %>%
        mutate(
          NM_DAP = coalesce(NM_DAP, NM_CAP_DAP1),
          NM_ALTURA = as.numeric(NM_ALTURA)
        )
      
      tabela_C <- df_final %>%
        group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
        summarise(
          PV50 = sum(NM_DAP^2 * NM_ALTURA, na.rm = TRUE),
          .groups = "drop"
        )
      
      tabela_D <- df_final %>%
        filter(CD_01 %in% LETTERS[1:24]) %>%
        group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
        summarise(
          DAP_MEDIO = mean(NM_DAP, na.rm = TRUE),
          ALTURA_MED = mean(NM_ALTURA, na.rm = TRUE),
          .groups = "drop"
        )
      
      list(
        dados = df_final,
        tabela_C = tabela_C,
        tabela_D = tabela_D
      )
    }
  )
)

# Exemplo de uso:
# otimizador <- OtimizadorIFQ6$new()
# resultado <- otimizador$validacao(c("caminho/para/arquivo1.xlsx", "caminho/para/arquivo2.xlsx", "caminho/para/SGF.xlsx"))
