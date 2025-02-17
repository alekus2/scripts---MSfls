> source("F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/bds/teste/teste.R", echo=TRUE)

> if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
+   install.packages("arcgisbinding", repos="https://r.esri.com")
+ }

> library(arcgisbinding)

> arc.check_product()
product: ArcGIS Pro (12.9.5.32739)
license: Advanced
version: 1.0.1.311 

> alocar_parcelas <- function(tabela_nome) {
+   arc.check_product()
+   tabela <- arc.open(tabela_nome)
+   df <- arc.select(tabela)
+   
+   if ("NM ..." ... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
Error in validObject(.Object) : 
  invalid class “SpatialPointsDataFrame” object: number of rows in data.frame and SpatialPoints don't match
> 
