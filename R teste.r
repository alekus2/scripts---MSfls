library(arcgisbinding)
library(sp)
library(dplyr)

# Ativar o ArcGIS binding
arc.check_product()

# Verificar se o shapefile existe antes de tentar abri-lo
shapefile_path <- "Pto_Qualidade_Parcelas_Piracicaba.shp"
if (!file.exists(shapefile_path)) {
  stop(paste("Erro: O arquivo", shapefile_path, "não foi encontrado."))
}

# Abrir o shapefile
tryCatch({
  tabela <- arc.open(shapefile_path)
}, error = function(e) {
  stop("Erro ao abrir o shapefile: ", e$message)
})

# Selecionar os dados garantindo que todos os registros sejam carregados
df <- tryCatch({
  arc.select(tabela, where_clause = "1=1")
}, error = function(e) {
  stop("Erro ao selecionar os dados do shapefile: ", e$message)
})

# Verificar se a coluna de geometria está presente
if (!"Shape" %in% colnames(df)) {
  stop("Erro: A coluna 'Shape' não está presente no shapefile.")
}

# Remover registros com geometria vazia
df <- df %>% filter(!is.na(Shape))

# Verificar se as colunas de coordenadas estão presentes
if (!all(c("POINT_X", "POINT_Y") %in% colnames(df))) {
  stop("Erro: As colunas de coordenadas 'POINT_X' e 'POINT_Y' não foram encontradas no shapefile.")
}

# Criar SpatialPointsDataFrame
coordinates(df) <- ~POINT_X+POINT_Y
proj4string(df) <- CRS("+init=epsg:31982")  # Verifique se o EPSG está correto

# Verificar se o objeto espacial foi criado corretamente
if (nrow(df) != length(df$Shape)) {
  stop("Erro: Número de registros no dataframe e pontos espaciais não coincidem.")
}

# Exibir os pontos
plot(df)

# Salvar o shapefile corrigido
tryCatch({
  arc.write("Pto_Qualidade_Parcelas_Piracicaba_corrigido.shp", df, overwrite = TRUE)
}, error = function(e) {
  stop("Erro ao salvar o shapefile corrigido: ", e$message)
})
