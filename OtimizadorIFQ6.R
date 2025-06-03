
R version 4.4.0 (2024-04-24 ucrt) -- "Puppy Cup"
Copyright (C) 2024 The R Foundation for Statistical Computing
Platform: x86_64-w64-mingw32/x64

R é um software livre e vem sem GARANTIA ALGUMA.
Você pode redistribuí-lo sob certas circunstâncias.
Digite 'license()' ou 'licence()' para detalhes de distribuição.

R é um projeto colaborativo com muitos contribuidores.
Digite 'contributors()' para obter mais informações e
'citation()' para saber como citar o R ou pacotes do R em publicações.

Digite 'demo()' para demonstrações, 'help()' para o sistema on-line de ajuda,
ou 'help.start()' para abrir o sistema de ajuda em HTML no seu navegador.
Digite 'q()' para sair do R.

[Workspace loaded from ~/.RData]

> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)

> library(R6)

> library(readxl)

> library(dplyr)

Anexando pacote: ‘dplyr’

Os seguintes objetos são mascarados por ‘package:stats’:

    filter, lag

Os seguintes objetos são mascarados por ‘package:base’:

    intersect, setdiff, setequal, union


> library(tidyr)

> library(purrr)

> library(stringr)

> library(lubridate)

Anexando pacote: ‘lubridate’

Os seguintes objetos são mascarados por ‘package:base’:

    date, intersect, setdiff, union


> library(openxlsx)

> library(glue)

> library(scales)

Anexando pacote: ‘scales’

O seguinte objeto é mascarado por ‘package:purrr’:

    discard


> `%notin%` <- function(x, y) !(x %in% y)

> OtimizadorIFQ6 <- R6Class("OtimizadorIFQ6",
+   public = list(
+     validacao = function(paths) {
+       # 1) colunas esperadas
+       nomes_colu .... [TRUNCATED] 

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
Mensagens de aviso:
1: pacote ‘R6’ foi compilado no R versão 4.4.3 
2: pacote ‘readxl’ foi compilado no R versão 4.4.3 
3: pacote ‘dplyr’ foi compilado no R versão 4.4.3 
4: pacote ‘tidyr’ foi compilado no R versão 4.4.3 
5: pacote ‘purrr’ foi compilado no R versão 4.4.3 
6: pacote ‘stringr’ foi compilado no R versão 4.4.3 
7: pacote ‘lubridate’ foi compilado no R versão 4.4.3 
8: pacote ‘openxlsx’ foi compilado no R versão 4.4.3 
9: pacote ‘glue’ foi compilado no R versão 4.4.3 
10: pacote ‘scales’ foi compilado no R versão 4.4.3 
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
+   public = list(
+     validacao = function(paths) {
+       # 1) colunas esperadas
+       nomes_colu .... [TRUNCATED] 

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
! `id_cols` can't select a column already selected by `values_from`.
i Column `Ht_media` has already been selected.
Run `rlang::last_trace()` to see where the error occurred.
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
+   public = list(
+     validacao = function(paths) {
+       # 1) colunas esperadas
+       nomes_colu .... [TRUNCATED] 

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
! Can't convert `fill` <double> to <list>.
Run `rlang::last_trace()` to see where the error occurred.
