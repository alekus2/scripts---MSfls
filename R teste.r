library(arcgisbinding)
library(sp)
library(dplyr)

# Ativar o ArcGIS binding
arc.check_product()

# Caminho do shapefile
tabela <- arc.open("Pto_Qualidade_Parcelas_Piracicaba.shp")

# Selecionar os dados garantindo que todos os registros sejam carregados
df <- arc.select(tabela, where_clause = "1=1")  # Retorna todos os registros

# Verificar se a coluna de geometria está presente
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
arc.write("Pto_Qualidade_Parcelas_Piracicaba_corrigido.shp", df, overwrite = TRUE)
