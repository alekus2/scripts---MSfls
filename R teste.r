> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/bds/teste/teste.R", echo=TRUE)

> library(arcgisbinding)

> library(sp)

> library(dplyr)

> arc.check_product()
product: ArcGIS Pro (12.9.5.32739)
license: Advanced
version: 1.0.1.311 

> shapefile_path <- "Pto_Qualidade_Piracicaba_Teste.shp"

> if (!file.exists(shapefile_path)) {
+   stop(paste("Erro: O arquivo", shapefile_path, "não foi encontrado."))
+ }
Error in eval(ei, envir) : 
  Erro: O arquivo Pto_Qualidade_Piracicaba_Teste.shp não foi encontrado.
> 
