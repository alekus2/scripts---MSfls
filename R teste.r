library(arcgisbinding)
library(sp)
library(dplyr)

arc.check_product()

shapefile_path <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/bds/teste/Pto_Qualidade_Parcelas_Piracicaba.shp"

if (!file.exists(shapefile_path)) {
  stop(paste("Erro: O arquivo", shapefile_path, "não foi encontrado."))
}

tabela <- tryCatch({
  arc.open(shapefile_path)
}, error = function(e) {
  stop("Erro ao abrir o shapefile: ", e$message)
})

df <- tryCatch({
  arc.select(tabela, where_clause = "1=1")
}, error = function(e) {
  stop("Erro ao selecionar os dados do shapefile: ", e$message)
})

if (!"Shape" %in% colnames(df)) {
  stop("Erro: A coluna 'Shape' não está presente no shapefile.")
}

df <- df %>% filter(!is.na(Shape))

if (!all(c("POINT_X", "POINT_Y") %in% colnames(df))) {
  stop("Erro: As colunas de coordenadas 'POINT_X' e 'POINT_Y' não foram encontradas no shapefile.")
}

coordinates(df) <- ~POINT_X+POINT_Y
proj4string(df) <- CRS("+init=epsg:31982")

if (nrow(df) != length(df$Shape)) {
  stop("Erro: Número de registros no dataframe e pontos espaciais não coincidem.")
}

plot(df)

tryCatch({
  arc.write(shapefile_path, df, overwrite = TRUE)
}, error = function(e) {
  stop("Erro ao salvar o shapefile: ", e$message)
})
