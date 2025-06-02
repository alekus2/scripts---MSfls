> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", encoding = 'UTF-8', echo=TRUE)

> library(readxl)

> library(dplyr)

> library(tidyr)

> library(purrr)

> library(stringr)

> library(lubridate)

> library(openxlsx)

> library(glue)

> library(scales)

> validacao_ifq6 <- function(paths) {
+   cols_esperadas <- c(
+     "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
+      .... [TRUNCATED] 

> pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/Ot ..." ... [TRUNCATED] 

> todos_xlsx <- list.files(
+   path        = pasta_dados,
+   pattern     = "\\.xlsx$",
+   full.names  = TRUE
+ )

> cadastro <- todos_xlsx[grepl("SGF", toupper(basename(todos_xlsx)))]

> ifq6      <- setdiff(todos_xlsx, cadastro)

> arquivos <- c(
+   cadastro,
+   ifq6
+ )

> stopifnot(all(file.exists(arquivos)))

> print(arquivos)
[1] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/base_dados_IFQ6_propria_fev.xlsx"

> validacao_ifq6(arquivos)
New names:
* `` -> `...35`
 [1] "CD_FAZENDA"         "CD_PROJETO"         "CD_TALHAO"          "DC_MAT_GEN"         "NM_PARCELA"         "DC_TIPO_PARCELA"    "DC_FORMA_PARCELA"   "NM_AREA_PARCELA"   
 [9] "NM_LARG_PARCELA"    "NM_COMP_PARCELA"    "NM_DEC_LAR_PARCELA" "NM_DEC_COM_PARCELA" "DT_INICIAL"         "DT_FINAL"           "CD_EQUIPE"          "NM_LATITUDE"       
[17] "NM_LONGITUDE"       "NM_ALTITUDE"        "DC_MATERIAL"        "TX_OBSERVACAO"      "NM_FILA"            "NM_COVA"            "NM_FUSTE"           "NM_DAP_ANT"        
[25] "NM_ALTURA_ANT"      "NM_CAP_DAP1"        "NM_DAP2"            "NM_DAP"             "NM_ALTURA"          "CD_01"              "CD_02"              "CD_03"             
[33] "NM_NOTA"            "DT_FIM_COVA"        "...35"             
Selecione (1=L,2=B,3=P): 3
Error in `rename()`:
! Names must be unique.
x These names are duplicated:
  * "NM_COVA" at locations 18 and 33.
Run `rlang::last_trace()` to see where the error occurred.
