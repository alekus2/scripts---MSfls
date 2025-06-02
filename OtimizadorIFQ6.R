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
 [1] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/Cadastro SGF (correto).xlsx"                  
 [2] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/~$04_Base IFQ6_APRIL_Ht3_2025.xlsx"           
 [3] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/04_Base IFQ6_APRIL_Ht3_2025.xlsx"             
 [4] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6271_TABOCA_SRP - IFQ6 (4).xlsx"              
 [5] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx"
 [6] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx"        
 [7] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx" 
 [8] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx"          
 [9] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx"           
[10] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx"         
[11] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx"      
[12] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/base_dados_IFQ6_propria_fev.xlsx"             
[13] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_10032025.xlsx"      
[14] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_17032025.xlsx"      
[15] "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados/IFQ6_MS_Florestal_Bravore_24032025.xlsx"      

> validacao_ifq6(arquivos)
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
New names:
* `` -> `...35`
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Selecione (1=L,2=B,3=P): 1
Error in `bind_rows()` at Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R:51:3:
! Can't combine `..1$CD_PROJETO` <double> and `..9$CD_PROJETO` <character>.
Run `rlang::last_trace()` to see where the error occurred.
Houve 50 ou mais avisos (use warnings() para ver os primeiros 50)
