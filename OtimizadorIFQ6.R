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
Error in nomes_colunas %notin% toupper(names(df)) : 
  não foi possível encontrar a função "%notin%"
