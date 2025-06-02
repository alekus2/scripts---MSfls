library(readxl)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(lubridate)
library(openxlsx)
library(glue)
library(scales)

validacao_ifq6 <- function(paths) {
  cols_esperadas <- c(
    "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
    "NM_LARG_PARCELA","NM_COMP_PARCELA","NM_DEC_LAR_PARCELA","NM_DEC_COM_PARCELA",
    "DT_INICIAL","DT_FINAL","CD_EQUIPE","NM_LATITUDE","NM_LONGITUDE","NM_ALTITUDE",
    "DC_MATERIAL","NM_FILA","NM_COVA","NM_FUSTE","NM_DAP_ANT","NM_ALTURA_ANT",
    "NM_CAP_DAP1","NM_DAP2","NM_DAP","NM_ALTURA","CD_01","CD_02","CD_03"
  )
  cadastro_path <- paths[str_detect(toupper(basename(paths)), "SGF")][1]
  arquivos_ifq6 <- paths[!paths %in% cadastro_path & file.exists(paths)]
  
  ler_ifq6 <- function(path) {
    df <- tryCatch(read_excel(path, sheet = 1), error = function(e) NULL)
    if (is.null(df) || nrow(df) == 0) {
      df <- tryCatch(read_excel(path, sheet = 2), error = function(e) NULL)
    }
    if (is.null(df) || nrow(df) == 0) return(NULL)
    names(df) <- ifelse(names(df) == "", paste0("new_col_", seq_along(df)), names(df))
    df <- df %>% mutate(CD_PROJETO = as.character(CD_PROJETO))
    if (!all(cols_esperadas %in% toupper(names(df)))) return(NULL)
    names(df) <- toupper(str_trim(names(df)))
    df %>% select(all_of(cols_esperadas))
  }
  
  atribuir_equipe <- function(path, cont) {
    nome <- toupper(basename(path))
    base <- case_when(
      str_detect(nome, "LEBATEC") ~ "lebatec",
      str_detect(nome, "BRAVORE") ~ "bravore",
      str_detect(nome, "PROPRIA") ~ "propria",
      TRUE ~ c("lebatec","bravore","propria")[as.integer(readline(glue("Selecione (1=L,2=B,3=P): ")))]
    )
    n <- cont[[base]] %||% 0
    cont[[base]] <- n + 1
    sufixo <- if (n==0) "" else sprintf("_%02d", n+1)
    list(equipe = paste0(base, sufixo), cont = cont)
  }
  
  cont_eq <- list()
  lista_dfs <- map(arquivos_ifq6, function(p) {
    df <- ler_ifq6(p)
    if (is.null(df)) return(NULL)
    tmp <- atribuir_equipe(p, cont_eq)
    cont_eq <<- tmp$cont
    df %>% mutate(EQUIPE = tmp$equipe)
  }) %>% compact()
  
  df_all <- bind_rows(lista_dfs)
  cols_dup <- c("CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_FILA","NM_COVA","NM_FUSTE","NM_ALTURA")
  df_all <- df_all %>%
    mutate(
      check_dup = if_else(duplicated(select(., all_of(cols_dup))) | duplicated(select(., all_of(cols_dup)), fromLast=TRUE), "VERIFICAR", "OK"),
      check_cd  = case_when(
        CD_01 %in% LETTERS[1:24] & NM_FUSTE==1 ~ "OK",
        CD_01=="L" & NM_FUSTE==1               ~ "VERIFICAR",
        TRUE                                   ~ "OK"
      ),
      CD_TALHAO = str_pad(str_sub(CD_TALHAO, -3), 3, "left", "0")
    )
  
  verifica_seq <- function(df) {
    last <- NA_integer_; ok <- TRUE
    for (i in seq_len(nrow(df))) {
      if (df$CD_01[i]=="L") {
        if (is.na(last)) last <- df$NM_COVA[i]
        if (df$NM_COVA[i]!=last) ok <- FALSE
      }
      if (df$CD_01[i]=="N") {
        if (is.na(last) || df$NM_COVA[i]!=last+1) ok <- FALSE
        last <- df$NM_COVA[i]
      }
    }
    ok
  }
  
  has_bad <- df_all %>% group_by(NM_FILA) %>% group_map(~ !verifica_seq(.x)) %>% unlist() %>% any()
  if (has_bad) {
    df_all <- df_all %>%
      arrange(NM_FILA) %>%
      group_by(NM_FILA) %>%
      mutate(
        idx = row_number(),
        new_cova = {
          seqs <- seq_len(n())
          for (i in seq_along(seqs)) {
            if (CD_01[i]=="L") {
              if (i>1 && NM_COVA[i]==NM_COVA[i-1]) seqs[i] <- seqs[i-1]
              else if (i<n() && NM_COVA[i]==NM_COVA[i+1]) seqs[i] <- seqs[i+1]
            }
          }
          seqs
        },
        check_sqc = if_else(idx==new_cova, "OK", "VERIFICAR")
      ) %>%
      ungroup() %>%
      rename(NM_COVA = new_cova) %>%
      select(-idx)
  } else {
    df_all <- df_all %>%
      arrange(NM_FILA, NM_COVA) %>%
      mutate(check_sqc = "OK") %>%
      group_by(NM_FILA) %>%
      mutate(
        check_sqc = if_else(CD_01=="N" & lag(CD_01)=="L" & lag(NM_FUSTE)==2 & NM_COVA==lag(NM_COVA), "VERIFICAR", check_sqc)
      ) %>%
      ungroup()
  }
  
  df_all <- df_all %>%
    mutate(`Ht média` = coalesce(NM_ALTURA, 0)) %>%
    arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, `Ht média`) %>%
    group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
    mutate(NM_COVA_ORDENADO = row_number()) %>%
    ungroup() %>%
    mutate(
      Chave_stand_1 = str_c(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
      DT_MEDIÇÃO1   = DT_INICIAL,
      EQUIPE_2      = CD_EQUIPE
    ) %>%
    select(-check_dup, -check_cd, -check_sqc)
  
  df_cad <- read_excel(cadastro_path, sheet = 1, col_types = "text") %>%
    mutate(Index = str_c(`Id Projeto`, Talhão))
  area_col <- names(df_cad)[str_detect(names(df_cad), regex("ÁREA", ignore_case = TRUE))]
  df_all <- df_all %>%
    mutate(
      Index = str_c(CD_PROJETO, CD_TALHAO) %>%
        str_replace("-(\\d)$", "-0\\1") %>%
        str_replace("^(?!.*-\\d{2}$)(.*)$", "\\1-01")
    ) %>%
    left_join(df_cad %>% select(Index, !!sym(area_col)), by = "Index") %>%
    rename(`Área (ha)` = !!sym(area_col)) %>%
    mutate(`Área (ha)` = coalesce(`Área (ha)`, "")) %>%
    rename(nm_parcela = NM_PARCELA, nm_area_parcela = NM_AREA_PARCELA)
  
  calcular_metricas <- function(vals) {
    n <- length(vals); meio <- floor(n/2); med <- if (n>0) median(vals) else 0
    tot <- sum(vals); ord <- sort(vals)
    le <- if (n%%2==0) sum(ord[1:meio][ord[1:meio] <= med]) else sum(ord[1:meio]) + med/2
    pv50 <- if (tot>0) le/tot*100 else 0.1
    tibble(n = n, `n/2` = meio, Mediana = med, `MHt` = tot, `MHt(<=Med)` = le, PV50 = pv50)
  }
  
  gera_tabela <- function(df_base, expo = 1) {
    pivot <- df_base %>%
      mutate(Ht = `Ht média`^expo) %>%
      pivot_wider(
        id_cols = c("Área (ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"),
        names_from = NM_COVA_ORDENADO,
        values_from = Ht,
        values_fill = 0
      )
    covas <- as.character(sort(as.integer(names(pivot)[-(1:6)])))
    met <- pivot %>% select(all_of(covas)) %>% pmap_dfr(calcular_metricas)
    codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
    falhas <- c("M","H","F","L","S")
    conts <- df_base %>%
      count(CD_PROJETO, CD_TALHAO, nm_parcela, CD_01) %>%
      pivot_wider(names_from = CD_01, values_from = n, values_fill = 0) %>%
      rename(NM_PARCELA = nm_parcela)
    tab <- pivot %>%
      bind_cols(met) %>%
      left_join(conts, by = c("CD_PROJETO","CD_TALHAO","nm_parcela" = "NM_PARCELA")) %>%
      replace(is.na(.), 0) %>%
      mutate(
        `Stand (tree/ha)` = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) * 10000 / as.numeric(nm_area_parcela),
        `Pits/ha`         = ((n - L) * 10000 / as.numeric(nm_area_parcela)),
        `%_Sobrevivência_decimal` = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) / rowSums(across(all_of(codes))),
        `%_Sobrevivência`  = percent(`%_Sobrevivência_decimal`, accuracy = 0.1, decimal.mark = ","),
        `Pits por sob`    = `Stand (tree/ha)` / `%_Sobrevivência_decimal`,
        `Check pits`      = `Pits por sob` - `Pits/ha`
      ) %>%
      select(-`%_Sobrevivência_decimal`)
    tab
  }
  
  df_tabela <- gera_tabela(df_all, expo = 1)
  df_D     <- gera_tabela(df_all, expo = 3) %>%
    mutate(`CHECK covas` = `Stand (tree/ha)`/(`Pits/ha`/`Pits por sob`),
           `CHECK impares/pares` = if_else(n %% 2 == 0, "Par", "Impar"))
  df_aux <- df_all %>% distinct(CD_PROJETO, CD_TALHAO, DC_MATERIAL, DT_MEDIÇÃO, EQUIPE_2)
  df_D <- left_join(df_D, df_aux, by = c("CD_PROJETO","CD_TALHAO")) %>%
    rename(`Material Genético` = DC_MATERIAL, `Data Medição` = DT_MEDIÇÃO1, Equipe = EQUIPE_2)
  mes  <- month(Sys.Date(), label = TRUE, abbr = FALSE)
  hoje <- format(Sys.Date(), "%Y%m%d")
  base <- glue("BASE_IFQ6_{mes}_{hoje}.xlsx")
  out  <- file.path(dirname(dirname(paths[1])), "output", base)
  dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
  wb <- createWorkbook()
  addWorksheet(wb, "Cadastro_SGF"); writeData(wb, "Cadastro_SGF", df_cad %>% select(-Index))
  addWorksheet(wb, paste0("Dados_CST_", mes)); writeData(wb, paste0("Dados_CST_", mes), df_all %>% select(-Index))
  addWorksheet(wb, "C_tabela_resultados"); writeData(wb, "C_tabela_resultados", df_tabela)
  addWorksheet(wb, "D_tabela_resultados_Ht3"); writeData(wb, "D_tabela_resultados_Ht3", df_D)
  saveWorkbook(wb, out, overwrite = TRUE)
  message("Tudo gravado em '", out, "'")
}

pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados"
todos_xlsx <- list.files(
  path        = pasta_dados,
  pattern     = "\\.xlsx$",
  full.names  = TRUE
)
cadastro <- todos_xlsx[grepl("SGF", toupper(basename(todos_xlsx)))]
ifq6      <- setdiff(todos_xlsx, cadastro)
arquivos <- c(
  cadastro,
  ifq6
)
stopifnot(all(file.exists(arquivos)))  
print(arquivos)

validacao_ifq6(arquivos)