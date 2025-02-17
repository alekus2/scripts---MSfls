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

# Remover registros com geometria vazia
df <- df %>% filter(!is.na(Shape))

# Criar o objeto espacial corretamente, assumindo que as colunas de coordenadas são 'POINT_X' e 'POINT_Y'
if (!all(c("POINT_X", "POINT_Y") %in% colnames(df))) {
  stop("Erro: As colunas de coordenadas 'POINT_X' e 'POINT_Y' não foram encontradas no shapefile.")
}

# Criar SpatialPointsDataFrame
df_spatial <- SpatialPointsDataFrame(
  coords = df[, c("POINT_X", "POINT_Y")],
  data = df,
  proj4string = CRS("+init=epsg:31982")  # Verifique se o EPSG está correto
)

# Verificar se o objeto espacial foi criado corretamente
if (nrow(df) != length(df_spatial)) {
  stop("Erro: Número de registros no dataframe e pontos espaciais não coincidem.")
}

# Exibir os pontos
plot(df_spatial)

# Salvar o shapefile corrigido
arc.write("Pto_Qualidade_Parcelas_Piracicaba_corrigido.shp", df_spatial, overwrite = TRUE)
