> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/bds/teste/teste.R", echo=TRUE)

> library(arcgisbinding)

> library(sp)

> library(dplyr)

> arc.check_product()
product: ArcGIS Pro (12.9.5.32739)
license: Advanced
version: 1.0.1.311 

> tabela <- arc.open("Pto_Qualidade_Parcelas_Piracicaba.shp")

> df <- arc.select(tabela, where_clause = "1=1")

> if (!"Shape" %in% colnames(df)) {
+   stop("Erro: A coluna 'Shape' não está presente no shapefile.")
+ }
Error in eval(ei, envir) : 
  Erro: A coluna 'Shape' não está presente no shapefile.
> 
