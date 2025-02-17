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
+   print(tabela)
+   df <- arc.select(tabela .... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
dataset_type    : FeatureClass
path            : Pto_Qualidade_Parcelas_Piracicaba.shp 
fields          : FID, Shape, OBJECTID_1, FID_VW_GIS, CD_USO_SOL, CD_UNIDADE, UNIDADE_GE, CD_REGIAO, CD_PROJETO, 
fields          : AREA_HA, CD_TRANSAC, DATA_CRIAC, CD_TALHAO, ID_PROJETO, ID_REGIAO, REGIAO, CODIGO_ANT, PROJETO, 
fields          : PROPRIEDAD, TIPO_CONTR, PROJETO_EX, USO_SOLO_P, USO_SOLO_F, ID_TALHAO, CICLO, ROTACAO, DISTANCIA_, 
fields          : DISTANCIA1, DISTANCI_1, DATA_PLANT, ANO_PLANTI, IDADE, ESPECIE, GENERO, CLASSE_SIT, DECLIVIDAD, 
fields          : MUNICIPIO, ESTADO, PAIS, BACIA_HIDR, CLASSE_SOL, TIPO_SOLO, DCAA_NUMER, DCAA_DATA_, DCAA_DATA1, 
fields          : PRECIPITAC, PROJETO_IN, AREA_MRP, BUFF_DIST, ORIG_FID, POINT_X, POINT_Y, INDEX_, NM_PARCELA, MES_PROG, 
fields          : TIPO_ATUAL, FORMA, DATA, DATA_ATUAL, PARCELAS, STATUS_CAM, REALOCADO, MOTIVO_REA, TIPO_DE_AV, EQUIPE
extent          : xmin=371470.2, ymin=7568486, xmax=378407.9, ymax=7574637
geometry type   : Point, has ZM
WKT             : PROJCS["SIRGAS_2000_UTM_Zone_22S",GEOGCS["GCS_SIRGAS_2000",D...
WKID            : 31982 
[1] 196
Error in validObject(.Object) : 
  invalid class “SpatialPointsDataFrame” object: number of rows in data.frame and SpatialPoints don't match
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
+   print(tabela)
+   df <- arc.select(tabela .... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
dataset_type    : FeatureClass
path            : Pto_Qualidade_Parcelas_Piracicaba.shp 
fields          : FID, Shape, OBJECTID_1, FID_VW_GIS, CD_USO_SOL, CD_UNIDADE, UNIDADE_GE, CD_REGIAO, CD_PROJETO, 
fields          : AREA_HA, CD_TRANSAC, DATA_CRIAC, CD_TALHAO, ID_PROJETO, ID_REGIAO, REGIAO, CODIGO_ANT, PROJETO, 
fields          : PROPRIEDAD, TIPO_CONTR, PROJETO_EX, USO_SOLO_P, USO_SOLO_F, ID_TALHAO, CICLO, ROTACAO, DISTANCIA_, 
fields          : DISTANCIA1, DISTANCI_1, DATA_PLANT, ANO_PLANTI, IDADE, ESPECIE, GENERO, CLASSE_SIT, DECLIVIDAD, 
fields          : MUNICIPIO, ESTADO, PAIS, BACIA_HIDR, CLASSE_SOL, TIPO_SOLO, DCAA_NUMER, DCAA_DATA_, DCAA_DATA1, 
fields          : PRECIPITAC, PROJETO_IN, AREA_MRP, BUFF_DIST, ORIG_FID, POINT_X, POINT_Y, INDEX_, NM_PARCELA, MES_PROG, 
fields          : TIPO_ATUAL, FORMA, DATA, DATA_ATUAL, PARCELAS, STATUS_CAM, REALOCADO, MOTIVO_REA, TIPO_DE_AV, EQUIPE
extent          : xmin=371470.2, ymin=7568486, xmax=378407.9, ymax=7574637
geometry type   : Point, has ZM
WKT             : PROJCS["SIRGAS_2000_UTM_Zone_22S",GEOGCS["GCS_SIRGAS_2000",D...
WKID            : 31982 
[1] 196
Error in alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp") : 
  object 'df_spatial' not found
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
+   print(tabela)
+   df <- arc.select(tabela .... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
dataset_type    : FeatureClass
path            : Pto_Qualidade_Parcelas_Piracicaba.shp 
fields          : FID, Shape, OBJECTID_1, FID_VW_GIS, CD_USO_SOL, CD_UNIDADE, UNIDADE_GE, CD_REGIAO, CD_PROJETO, 
fields          : AREA_HA, CD_TRANSAC, DATA_CRIAC, CD_TALHAO, ID_PROJETO, ID_REGIAO, REGIAO, CODIGO_ANT, PROJETO, 
fields          : PROPRIEDAD, TIPO_CONTR, PROJETO_EX, USO_SOLO_P, USO_SOLO_F, ID_TALHAO, CICLO, ROTACAO, DISTANCIA_, 
fields          : DISTANCIA1, DISTANCI_1, DATA_PLANT, ANO_PLANTI, IDADE, ESPECIE, GENERO, CLASSE_SIT, DECLIVIDAD, 
fields          : MUNICIPIO, ESTADO, PAIS, BACIA_HIDR, CLASSE_SOL, TIPO_SOLO, DCAA_NUMER, DCAA_DATA_, DCAA_DATA1, 
fields          : PRECIPITAC, PROJETO_IN, AREA_MRP, BUFF_DIST, ORIG_FID, POINT_X, POINT_Y, INDEX_, NM_PARCELA, MES_PROG, 
fields          : TIPO_ATUAL, FORMA, DATA, DATA_ATUAL, PARCELAS, STATUS_CAM, REALOCADO, MOTIVO_REA, TIPO_DE_AV, EQUIPE
extent          : xmin=371470.2, ymin=7568486, xmax=378407.9, ymax=7574637
geometry type   : Point, has ZM
WKT             : PROJCS["SIRGAS_2000_UTM_Zone_22S",GEOGCS["GCS_SIRGAS_2000",D...
WKID            : 31982 
[1] 196
Error: arc.write() - 'coords' and 'data' are NULL
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
+   print(tabela)
+   df <- arc.select(tabela .... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
dataset_type    : FeatureClass
path            : Pto_Qualidade_Parcelas_Piracicaba.shp 
fields          : FID, Shape, OBJECTID_1, FID_VW_GIS, CD_USO_SOL, CD_UNIDADE, UNIDADE_GE, CD_REGIAO, CD_PROJETO, 
fields          : AREA_HA, CD_TRANSAC, DATA_CRIAC, CD_TALHAO, ID_PROJETO, ID_REGIAO, REGIAO, CODIGO_ANT, PROJETO, 
fields          : PROPRIEDAD, TIPO_CONTR, PROJETO_EX, USO_SOLO_P, USO_SOLO_F, ID_TALHAO, CICLO, ROTACAO, DISTANCIA_, 
fields          : DISTANCIA1, DISTANCI_1, DATA_PLANT, ANO_PLANTI, IDADE, ESPECIE, GENERO, CLASSE_SIT, DECLIVIDAD, 
fields          : MUNICIPIO, ESTADO, PAIS, BACIA_HIDR, CLASSE_SOL, TIPO_SOLO, DCAA_NUMER, DCAA_DATA_, DCAA_DATA1, 
fields          : PRECIPITAC, PROJETO_IN, AREA_MRP, BUFF_DIST, ORIG_FID, POINT_X, POINT_Y, INDEX_, NM_PARCELA, MES_PROG, 
fields          : TIPO_ATUAL, FORMA, DATA, DATA_ATUAL, PARCELAS, STATUS_CAM, REALOCADO, MOTIVO_REA, TIPO_DE_AV, EQUIPE
extent          : xmin=371470.2, ymin=7568486, xmax=378407.9, ymax=7574637
geometry type   : Point, has ZM
WKT             : PROJCS["SIRGAS_2000_UTM_Zone_22S",GEOGCS["GCS_SIRGAS_2000",D...
WKID            : 31982 
Error in .call_proxy("table.select", object, fields, as.pairlist(args)) : 
  incorrect type, argument: where_clause
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
+   print(tabela)
+   df <- arc.select(tabela .... [TRUNCATED] 

> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
dataset_type    : FeatureClass
path            : Pto_Qualidade_Parcelas_Piracicaba.shp 
fields          : FID, Shape, OBJECTID_1, FID_VW_GIS, CD_USO_SOL, CD_UNIDADE, UNIDADE_GE, CD_REGIAO, CD_PROJETO, 
fields          : AREA_HA, CD_TRANSAC, DATA_CRIAC, CD_TALHAO, ID_PROJETO, ID_REGIAO, REGIAO, CODIGO_ANT, PROJETO, 
fields          : PROPRIEDAD, TIPO_CONTR, PROJETO_EX, USO_SOLO_P, USO_SOLO_F, ID_TALHAO, CICLO, ROTACAO, DISTANCIA_, 
fields          : DISTANCIA1, DISTANCI_1, DATA_PLANT, ANO_PLANTI, IDADE, ESPECIE, GENERO, CLASSE_SIT, DECLIVIDAD, 
fields          : MUNICIPIO, ESTADO, PAIS, BACIA_HIDR, CLASSE_SOL, TIPO_SOLO, DCAA_NUMER, DCAA_DATA_, DCAA_DATA1, 
fields          : PRECIPITAC, PROJETO_IN, AREA_MRP, BUFF_DIST, ORIG_FID, POINT_X, POINT_Y, INDEX_, NM_PARCELA, MES_PROG, 
fields          : TIPO_ATUAL, FORMA, DATA, DATA_ATUAL, PARCELAS, STATUS_CAM, REALOCADO, MOTIVO_REA, TIPO_DE_AV, EQUIPE
extent          : xmin=371470.2, ymin=7568486, xmax=378407.9, ymax=7574637
geometry type   : Point, has ZM
WKT             : PROJCS["SIRGAS_2000_UTM_Zone_22S",GEOGCS["GCS_SIRGAS_2000",D...
WKID            : 31982 
Error in .call_proxy("table.select", object, fields, as.pairlist(args)) : 
  incorrect type, argument: where_clause
> 
