> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", echo=TRUE)

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

> pasta_dados <- "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação e ..." ... [TRUNCATED] 

> arquivos <- list.files(
+   path       = pasta_dados,
+   pattern    = "\\.xlsx$",
+   full.names = TRUE,
+   recursive = TRUE
+ )

> arquivos <- c(
+   arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
+   setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)),  .... [TRUNCATED] 

> print(arquivos)
 [1] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/Cadastro SGF (correto).xlsx"                  
 [2] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6271_TABOCA_SRP - IFQ6 (4).xlsx"              
 [3] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx"
 [4] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx"        
 [5] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx" 
 [6] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx"          
 [7] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx"           
 [8] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx" 
 [9] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx"         
[10] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx"      
[11] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/base_dados_IFQ6_propria_fev.xlsx"             
[12] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_10032025.xlsx"      
[13] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_17032025.xlsx"      
[14] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_24032025.xlsx"      

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
Error in otimizador$validacao(arquivos) : objeto 'df_c' não encontrado
> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/OtimizadorIFQ6.R", echo=TRUE)

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

> pasta_dados <- "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação e ..." ... [TRUNCATED] 

> arquivos <- list.files(
+   path       = pasta_dados,
+   pattern    = "\\.xlsx$",
+   full.names = TRUE,
+   recursive = TRUE
+ )

> arquivos <- c(
+   arquivos[str_detect(toupper(basename(arquivos)), "SGF")],
+   setdiff(arquivos, arquivos[str_detect(toupper(basename(arquivos)),  .... [TRUNCATED] 

> print(arquivos)
 [1] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/Cadastro SGF (correto).xlsx"                  
 [2] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6271_TABOCA_SRP - IFQ6 (4).xlsx"              
 [3] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx"
 [4] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx"        
 [5] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx" 
 [6] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx"          
 [7] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx"           
 [8] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6) - Copia.xlsx" 
 [9] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx"         
[10] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/6439_TREZE_DE_JULHO_RRP - IFQ6 (4).xlsx"      
[11] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/base_dados_IFQ6_propria_fev.xlsx"             
[12] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_10032025.xlsx"      
[13] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_17032025.xlsx"      
[14] "F://Qualidade_Florestal//02- MATO GROSSO DO SUL//11- Administrativo Qualidade MS//00- Colaboradores//17 - Alex Vinicius//Automação em R//OtimizadorIFQ6//dados at/IFQ6_MS_Florestal_Bravore_24032025.xlsx"      

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
Error in `mutate()`:
i In argument: `Stand_tree_ha = `/`(...)`.
Caused by error in `across()`:
i In argument: `all_of(codes)`.
Caused by error in `all_of()`:
! Can't subset elements that don't exist.
x Elements `A`, `D`, `G`, `J`, `S`, etc. don't exist.
Run `rlang::last_trace()` to see where the error occurred.
