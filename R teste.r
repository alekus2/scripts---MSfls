library(arcgisbinding)
library(sp)
library(dplyr)

arc.check_product()

shapefile_path <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/bds/teste/Pto_Qualidade_Parcelas_Piracicaba.shp"

if (!arc.exists(shapefile_path)) {
  stop("Erro: O arquivo não foi encontrado.")
}

tabela <- arc.open(shapefile_path)

df <- arc.select(tabela, where_clause = "1=1")

if (!"Shape" %in% colnames(df)) {
  stop("Erro: A coluna 'Shape' não está presente no shapefile.")
}

df <- df %>% filter(!is.na(Shape))

if (!all(c("POINT_X", "POINT_Y") %in% colnames(df))) {
  stop("Erro: As colunas 'POINT_X' e 'POINT_Y' não foram encontradas.")
}

coordinates(df) <- ~POINT_X+POINT_Y
proj4string(df) <- CRS("+init=epsg:31982")

if (nrow(df) != length(df$Shape)) {
  stop("Erro: Número de registros e pontos espaciais não coincidem.")
}

plot(df)

arc.write(shapefile_path, df, overwrite = TRUE)
