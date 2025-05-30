library(readxl)
library(dplyr)
library(tidyr)
library(openxlsx)
library(lubridate)
library(stringr)

OtimizadorIFQ6 <- function(paths) {
  nomes_colunas <- c(
    "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
    "NM_LARG_PARCELA","NM_COMP_PARCELA","NM_DEC_LAR_PARCELA","NM_DEC_COM_PARCELA",
    "DT_INICIAL","DT_FINAL","CD_EQUIPE","NM_LATITUDE","NM_LONGITUDE","NM_ALTITUDE",
    "DC_MATERIAL","NM_FILA","NM_COVA","NM_FUSTE","NM_DAP_ANT","NM_ALTURA_ANT",
    "NM_CAP_DAP1","NM_DAP2","NM_DAP","NM_ALTURA","CD_01","CD_02","CD_03"
  )
  
  meses      <- c("Janeiro","Fevereiro","Marco","Abril","Maio","Junho",
                  "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro")
  mes_atual  <- month(Sys.Date())
  nome_mes   <- meses[mes_atual]
  data_emissao <- format(Sys.Date(), "%Y%m%d")
  
  base_dir     <- dirname(paths[1])
  pasta_mes    <- file.path(dirname(base_dir), nome_mes)
  pasta_output <- file.path(pasta_mes, "output")
  dir.create(pasta_output, showWarnings = FALSE, recursive = TRUE)
  
  cadastro_path <- paths[grepl("SGF", toupper(basename(paths)))][1]
  lista_df      <- list()
  equipes       <- list()

  for (path in paths) {
    if (!file.exists(path) || identical(path, cadastro_path)) next
    
    nome_arquivo <- toupper(basename(path))
    base <- case_when(
      str_detect(nome_arquivo, "LEBATEC") ~ "lebatec",
      str_detect(nome_arquivo, "BRAVORE") ~ "bravore",
      str_detect(nome_arquivo, "PROPRIA")  ~ "propria",
      TRUE ~ {
        escolha <- ""
        while (!escolha %in% c("1","2","3")) {
          escolha <- readline("Selecione equipe (1-LEBATEC,2-BRAVORE,3-PROPRIA): ")
        }
        c("lebatec","bravore","propria")[as.numeric(escolha)]
      }
    )
    equipes[[base]] <- ifelse(is.null(equipes[[base]]), 1, equipes[[base]] + 1)
    sufixo <- if (equipes[[base]]==1) "" else paste0("_", sprintf("%02d", equipes[[base]]))
    equipe  <- paste0(base, sufixo)
    
    # tenta ler aba 1
    df <- tryCatch(read_excel(path, sheet = 1), error = function(e) NULL)
    if (is.null(df)) next
    df <- df %>% rename_with(toupper) %>% mutate(across(everything(), trimws))
    
    falt <- setdiff(nomes_colunas, names(df))
    if (length(falt)>0) {
      df2 <- tryCatch(read_excel(path, sheet = 2), error = function(e) NULL)
      if (!is.null(df2)) {
        df2 <- df2 %>% rename_with(toupper) %>% mutate(across(everything(), trimws))
        if (all(nomes_colunas %in% names(df2))) df <- df2
      }
    }
    if (!all(nomes_colunas %in% names(df))) next
    
    lista_df[[length(lista_df)+1]] <- df %>%
      select(all_of(nomes_colunas)) %>%
      mutate(EQUIPE = equipe)
  }
  
  if (length(lista_df)==0) {
    cat("Nenhum arquivo IFQ6 processado.\n"); return(invisible(NULL))
  }
  
  df_final <- bind_rows(lista_df)

  dup_cols <- c("CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_FILA","NM_COVA","NM_FUSTE","NM_ALTURA")
  df_final <- df_final %>%
    mutate(
      check_dup = if_else(
        duplicated(select(., all_of(dup_cols))) |
          duplicated(select(., all_of(dup_cols)), fromLast = TRUE),
        "VERIFICAR","OK"
      ),
      check_cd = case_when(
        CD_01 %in% LETTERS[1:24] & NM_FUSTE==1 ~ "OK",
        CD_01=="L" & NM_FUSTE==1 ~ "VERIFICAR",
        TRUE ~ "OK"
      ),
      CD_TALHAO = str_sub(as.character(CD_TALHAO), -3) %>% str_pad(3, "left", "0")
    )
  
  seq_check <- function(g) {
    last <- NA_integer_
    for (i in seq_len(nrow(g))) {
      if (g$CD_01[i]=="L") {
        if (!is.na(last) && g$NM_COVA[i]!=last) return(FALSE)
        last <- g$NM_COVA[i]
      } else if (g$CD_01[i]=="N") {
        if (is.na(last) || g$NM_COVA[i]!=last+1) return(FALSE)
        last <- g$NM_COVA[i]
      }
    }
    TRUE
  }
  
  by_fila <- split(df_final, df_final$NM_FILA)
  df_final$check_sqc <- "OK"
  for (nm in names(by_fila)) {
    if (!seq_check(by_fila[[nm]])) {
      df_final$check_sqc[rownames(by_fila[[nm]])] <- "VERIFICAR"
    }
  }
  
  n_ver <- sum(df_final$check_sqc=="VERIFICAR")
  cat(sprintf("Quantidade de 'VERIFICAR': %d\n", n_ver))
  if (n_ver>0) {
    resp <- readline("Deseja verificar agora? (s/n): ")
    if (tolower(resp)=="s") {
      base_out <- sprintf("IFQ6_%s_%s", nome_mes, data_emissao)
      cnt <- 1
      outx <- file.path(pasta_output, sprintf("%s_%02d.xlsx", base_out, cnt))
      while (file.exists(outx)) {
        cnt <- cnt+1
        outx <- file.path(pasta_output, sprintf("%s_%02d.xlsx", base_out, cnt))
      }
      write.xlsx(df_final, outx, rowNames=FALSE)
      cat("Salvo em:", outx, "\n")
      return(invisible(NULL))
    }
  }

  df_final <- df_final %>%
    mutate(
      Ht_media = coalesce(as.numeric(NM_ALTURA), 0)
    ) %>%
    arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, Ht_media) %>%
    group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA) %>%
    mutate(NM_COVA_ORDENADO = row_number()) %>%
    ungroup() %>%
    mutate(
      Chave_stand_1 = paste0(CD_PROJETO,"-",CD_TALHAO,"-",NM_PARCELA),
      DT_MEDICAO1   = DT_INICIAL,
      EQUIPE_2      = CD_EQUIPE
    ) %>%
    select(-check_dup, -check_cd, -check_sqc)

  df_cad <- read_excel(cadastro_path, sheet = 1) %>%
    rename_with(~ str_replace_all(., "[^A-Za-z0-9_]", "")) %>%
    mutate(
      Talhao_z3 = str_sub(as.character(Talhao), -3) %>% str_pad(3, "left", "0"),
      Index_z3  = paste0(trimws(`IdProjeto`), Talhao_z3)
    )
  area_col <- names(df_cad)[grepl("AREA", toupper(names(df_cad)))]
  
  df_final <- df_final %>%
    mutate(Index_z3 = paste0(trimws(CD_PROJETO), CD_TALHAO)) %>%
    left_join(
      df_cad %>% select(Index_z3, all_of(area_col)),
      by = "Index_z3"
    ) %>%
    rename(Area_ha = all_of(area_col)) %>%
    mutate(Area_ha = coalesce(as.numeric(Area_ha), NA))

  calc_metrics <- function(vals) {
    nonzero <- vals[vals > 0]
    n     <- length(nonzero)
    med   <- if (n>0) median(nonzero) else 0
    tot   <- sum(nonzero)
    ord   <- sort(nonzero)
    meio  <- floor(n/2)
    le    <- if (n%%2==0) sum(ord[1:meio][ord[1:meio] <= med]) else sum(ord[1:meio]) + med/2
    pv50  <- if (tot>0) le/tot*100 else 0
    data.frame(n=n, Mediana=med, `3Ht`=tot, PV50=pv50)
  }

  df_res   <- df_final
  df_res <- df_res %>%
    rename(
      nm_parcela       = NM_PARCELA,
      nm_area_parcela  = NM_AREA_PARCELA
    )
  
  df_pivot <- df_res %>%
    pivot_wider(
      names_from   = NM_COVA_ORDENADO,
      values_from  = Ht_media,
      values_fill  = 0
    ) %>%
    arrange(CD_PROJETO, CD_TALHAO, nm_parcela)
  
  cols0 <- c("Area_ha","Chave_stand_1","CD_PROJETO","CD_TALHAO","nm_parcela","nm_area_parcela")
  num_cols <- sort(as.numeric(names(df_pivot)[!names(df_pivot) %in% cols0]))

  metrics <- df_pivot %>%
    select(all_of(num_cols)) %>%
    as.data.frame() %>%
    split(1:nrow(.), seq_len(nrow(.))) %>%
    lapply(function(r) calc_metrics(unlist(r))) %>%
    bind_rows()
  
  df_tabela <- bind_cols(df_pivot[cols0], metrics)
  
  # contagens por CD_01
  codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
  falhas <- c("M","H","F","L","S")
  
  counts <- df_final %>%
    group_by(CD_PROJETO, CD_TALHAO, nm_parcela) %>%
    summarise(count = n(), .groups="drop") %>%
    # se precisar detalhar por CD_01, voce pode adaptar aqui
    pivot_wider(names_from = CD_01, values_from = count, values_fill = 0)
  
  df_tabela <- df_tabela %>%
    left_join(counts, by = c("CD_PROJETO","CD_TALHAO","nm_parcela")) %>%
    replace_na(list()) %>%
    mutate(
      `Stand (tree/ha)`  = (rowSums(across(all_of(codes)), na.rm=TRUE)
                            - rowSums(across(all_of(falhas)), na.rm=TRUE))
      * 10000 / as.numeric(nm_area_parcela),
      Pits_per_ha       = ((n - L) * 10000 / as.numeric(nm_area_parcela)) %>% replace_na(0)
    )
  
  medianas <- df_final %>%
    group_by(CD_PROJETO, CD_TALHAO) %>%
    summarise(Media_Ht = median(Ht_media), .groups="drop")
  
  df_tabela <- df_tabela %>%
    left_join(medianas, by = c("CD_PROJETO","CD_TALHAO")) %>%
    mutate(
      tot  = rowSums(across(all_of(codes)), na.rm=TRUE),
      valid= tot - rowSums(across(all_of(falhas)), na.rm=TRUE),
      surv = if_else(tot>0, valid/tot, 0),
      `%_Sobrevivencia`            = paste0(round(surv*100,1),"%"),
      `%_Sobrevivencia_decimal`    = surv,
      `Pits_por_sobrevivente`      = `Stand (tree/ha)` / surv,
      `Check_pits`                 = `Pits_por_sobrevivente` - Pits_per_ha
    ) %>%
    select(-tot, -valid)

  df_D <- df_res %>%
    pivot_wider(
      names_from  = NM_COVA_ORDENADO,
      values_from = Ht_media,
      values_fill = 0
    )
  # habiliar cubo
  df_D[num_cols] <- df_D[num_cols]^3
  
  metrics_D <- df_D %>%
    select(all_of(num_cols)) %>%
    as.data.frame() %>%
    split(1:nrow(.), seq_len(nrow(.))) %>%
    lapply(function(r) calc_metrics(unlist(r))) %>%
    bind_rows()
  
  df_D_resultados <- bind_cols(df_D[cols0], metrics_D) %>%
    left_join(counts, by = c("CD_PROJETO","CD_TALHAO","nm_parcela")) %>%
    replace_na(list()) %>%
    mutate(
      `Stand (tree/ha)` = (rowSums(across(all_of(codes)), na.rm=TRUE)
                           - rowSums(across(all_of(falhas)), na.rm=TRUE))
      * 10000 / as.numeric(nm_area_parcela),
      Pits_per_ha       = ((n - L) * 10000 / as.numeric(nm_area_parcela)) %>% replace_na(0)
    ) %>%
    left_join(medianas, by = c("CD_PROJETO","CD_TALHAO")) %>%
    mutate(
      tot_D   = rowSums(across(all_of(codes)), na.rm=TRUE),
      valid_D = tot_D - rowSums(across(all_of(falhas)), na.rm=TRUE),
      surv_D  = if_else(tot_D>0, valid_D/tot_D, 0),
      `%_Sobrevivencia`     = paste0(round(surv_D*100,1),"%"),
      CHECK_covas           = `Stand (tree/ha)` / surv_D,
      CHECK_pits            = CHECK_covas - Pits_per_ha,
      CHECK_impares_pares   = if_else(n %% 2 == 0, "Par", "Impar"),
      `%_K`                 = paste0(round(K/(n-L)*100,1),"%"),
      `%_L`                 = paste0(round((H+I)/(n-L)*100,1),"%")
    ) %>%
    select(-tot_D, -valid_D)

  nome_base <- sprintf("BASE_IFQ6_%s_%s", nome_mes, data_emissao)
  cnt <- 1
  out2 <- file.path(pasta_output, sprintf("%s_%02d.xlsx", nome_base, cnt))
  while (file.exists(out2)) {
    cnt <- cnt + 1
    out2 <- file.path(pasta_output, sprintf("%s_%02d.xlsx", nome_base, cnt))
  }
  
  write.xlsx(df_cad,           file = out2, sheetName = "Cadastro_SGF",               rowNames = FALSE)
  write.xlsx(df_final,         file = out2, sheetName = paste0("Dados_CST_",nome_mes), append   = TRUE, rowNames = FALSE)
  write.xlsx(df_tabela,        file = out2, sheetName = "C_tabela_resultados",        append   = TRUE, rowNames = FALSE)
  write.xlsx(df_D_resultados,  file = out2, sheetName = "D_tabela_resultados_Ht3",     append   = TRUE, rowNames = FALSE)
  
  cat("Tudo gravado em:", out2, "\n")
}

arquivos <- c(
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6271_TABOCA_SRP - IFQ6 (4).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/base_dados_IFQ6_propria_fev.xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/Cadastro SGF (correto).xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_10032025.xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_17032025.xlsx",
  "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_24032025.xlsx"
)

OtimizadorIFQ6(arquivos)

> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)
> library(readxl)
> library(dplyr)
> library(tidyr)
> library(openxlsx)
> library(lubridate)
> library(stringr)
> OtimizadorIFQ6 <- function(paths) {
+   nomes_colunas <- c(
+     "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
+     " ..." ... [TRUNCATED] 
> arquivos <- c(
+   "F:Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R ..." ... [TRUNCATED] 
> OtimizadorIFQ6(arquivos)
Nenhum arquivo IFQ6 processado.
