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
 [1] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/Cadastro SGF (correto).xlsx"                  
 [2] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6271_TABOCA_SRP - IFQ6 (4).xlsx"              
 [3] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx"
 [4] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx"        
 [5] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx" 
 [6] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx"          
 [7] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx"           
 [8] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx" 
 [9] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx"         
[10] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx"      
[11] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/base_dados_IFQ6_propria_fev.xlsx"             
[12] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/IFQ6_MS_Florestal_Bravore_10032025.xlsx"      
[13] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/IFQ6_MS_Florestal_Bravore_17032025.xlsx"      
[14] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados at/IFQ6_MS_Florestal_Bravore_24032025.xlsx"      

> validacao_ifq6(arquivos)
 [1] "cd_projeto"         "cd_talhao"          "nm_parcela"         "dc_tipo_parcela"    "dc_forma_parcela"   "nm_area_parcela"    "nm_larg_parcela"    "nm_comp_parcela"   
 [9] "nm_dec_lar_parcela" "nm_dec_com_parcela" "dt_inicial"         "dt_final"           "cd_equipe"          "nm_latitude"        "nm_longitude"       "nm_altitude"       
[17] "dc_material"        "nm_fila"            "nm_cova"            "nm_fuste"           "nm_dap_ant"         "nm_altura_ant"      "nm_cap_dap1"        "nm_dap2"           
[25] "nm_dap"             "nm_altura"          "cd_01"              "cd_02"              "cd_03"              "nm_nota"            "dif_dap"            "dif_altura"        
[33] "Descrição"          "Fechamento"        
Error in `map()`:
i In index: 1.
Caused by error in `mutate()`:
i In argument: `CD_PROJETO = as.character(CD_PROJETO)`.
Caused by error:
! objeto 'CD_PROJETO' não encontrado
Run `rlang::last_trace()` to see where the error occurred


agr ta explicado, o codigo deveria transformar as colunas em maiusculas para verificações!!! isso em tds arquivos.
