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

      # Continuação do código conforme necessário...
    }
  )
)

> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)

> library(R6)

> library(readxl)

> library(dplyr)

> library(tidyr)

> library(purrr)

> library(stringr)

> library(lubridate)

> library(openxlsx)

> library(glue)

> library(scales)

> `%notin%` <- function(x, y) !(x %in% y)

> OtimizadorIFQ6 <- R6Class("OtimizadorIFQ6",
+                           public = list(
+                             validacao = function(paths) {
+ .... [TRUNCATED] 

> pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/Ot ..." ... [TRUNCATED] 

> arquivos <- list.files(
+   path       = pasta_dados,
+   pattern    = "\\.xlsx$",
+   full.names = TRUE
+ )

> arquivos <- c(
+   arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
+   setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)),  .... [TRUNCATED] 

> otimizador <- OtimizadorIFQ6$new()

> otimizador$validacao(arquivos)
Arquivo sem equipe identificada automaticamente: 6271_TABOCA_SRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6348_BERRANTE_II_RRP - IFQ6 (29).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
New names:
* `` -> `...35`
Quantidade de VERIFICAR: 266
Deseja verificar agora? (s/n): s
Dados salvos em F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/Junho/output/IFQ6_Junho_20250602_02.xlsx
> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)

> library(R6)

> library(readxl)

> library(dplyr)

> library(tidyr)

> library(purrr)

> library(stringr)

> library(lubridate)

> library(openxlsx)

> library(glue)

> library(scales)

> `%notin%` <- function(x, y) !(x %in% y)

> OtimizadorIFQ6 <- R6Class("OtimizadorIFQ6",
+                           public = list(
+                             validacao = function(paths) {
+ .... [TRUNCATED] 

> pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/Ot ..." ... [TRUNCATED] 

> arquivos <- list.files(
+   path       = pasta_dados,
+   pattern    = "\\.xlsx$",
+   full.names = TRUE
+ )

> arquivos <- c(
+   arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
+   setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)),  .... [TRUNCATED] 

> otimizador <- OtimizadorIFQ6$new()

> otimizador$validacao(arquivos)
Arquivo sem equipe identificada automaticamente: 6271_TABOCA_SRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6348_BERRANTE_II_RRP - IFQ6 (29).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
New names:
* `` -> `...35`
Quantidade de VERIFICAR: 0
Error in `pivot_wider()`:
! Can't select columns that don't exist.
x Column `NM_COVA_ORDENADO` doesn't exist.
Run `rlang::last_trace()` to see where the error occurred.
> rlang::last_trace()
<error/vctrs_error_subscript_oob>
Error in `pivot_wider()`:
! Can't select columns that don't exist.
x Column `NM_COVA_ORDENADO` doesn't exist.
---
Backtrace:
    x
 1. +-base::source(...)
 2. | +-base::withVisible(eval(ei, envir))
 3. | \-base::eval(ei, envir)
 4. |   \-base::eval(ei, envir)
 5. +-otimizador$validacao(arquivos) at Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R:316:1
 6. | \-df_final %>% ... at Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R:228:31
 7. +-tidyr::pivot_wider(...)
 8. \-tidyr:::pivot_wider.data.frame(...)
Run rlang::last_trace(drop = FALSE) to see 15 hidden frames.
> rlang::last_trace(drop = FALSE)
<error/vctrs_error_subscript_oob>
Error in `pivot_wider()`:
! Can't select columns that don't exist.
x Column `NM_COVA_ORDENADO` doesn't exist.
---
Backtrace:
     x
  1. +-base::source(...)
  2. | +-base::withVisible(eval(ei, envir))
  3. | \-base::eval(ei, envir)
  4. |   \-base::eval(ei, envir)
  5. +-otimizador$validacao(arquivos) at Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R:316:1
  6. | \-df_final %>% ... at Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R:228:31
  7. +-tidyr::pivot_wider(...)
  8. +-tidyr:::pivot_wider.data.frame(...)
  9. | \-tidyr::build_wider_spec(...)
 10. |   \-tidyselect::eval_select(...)
 11. |     \-tidyselect:::eval_select_impl(...)
 12. |       +-tidyselect:::with_subscript_errors(...)
 13. |       | \-base::withCallingHandlers(...)
 14. |       \-tidyselect:::vars_select_eval(...)
 15. |         \-tidyselect:::walk_data_tree(expr, data_mask, context_mask)
 16. |           \-tidyselect:::as_indices_sel_impl(...)
 17. |             \-tidyselect:::as_indices_impl(...)
 18. |               \-tidyselect:::chr_as_locations(x, vars, call = call, arg = arg)
 19. |                 \-vctrs::vec_as_location(...)
 20. \-vctrs (local) `<fn>`()
 21.   \-vctrs:::stop_subscript_oob(...)
 22.     \-vctrs:::stop_subscript(...)
 23.       \-rlang::abort(...)
> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)

> library(R6)

> library(readxl)

> library(dplyr)

> library(tidyr)

> library(purrr)

> library(stringr)

> library(lubridate)

> library(openxlsx)

> library(glue)

> library(scales)

> `%notin%` <- function(x, y) !(x %in% y)

> OtimizadorIFQ6 <- R6Class("OtimizadorIFQ6",
+                           public = list(
+                             validacao = function(paths) {
+ .... [TRUNCATED] 

> pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/Ot ..." ... [TRUNCATED] 

> arquivos <- list.files(
+   path       = pasta_dados,
+   pattern    = "\\.xlsx$",
+   full.names = TRUE
+ )

> arquivos <- c(
+   arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
+   setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)),  .... [TRUNCATED] 

> otimizador <- OtimizadorIFQ6$new()

> otimizador$validacao(arquivos)
Arquivo sem equipe identificada automaticamente: 6271_TABOCA_SRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6348_BERRANTE_II_RRP - IFQ6 (29).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
Arquivo sem equipe identificada automaticamente: 6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx
Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): 1
New names:
* `` -> `...35`
Quantidade de VERIFICAR: 0
Error in `pivot_wider()`:
! Can't select columns that don't exist.
x Column `NM_COVA_ORDENADO` doesn't exist.
Run `rlang::last_trace()` to see where the error occurred.
