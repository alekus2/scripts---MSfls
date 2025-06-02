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
