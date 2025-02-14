library(arcgisbinding)

alocar_parcelas <- function(tabela_nome) {
  arc.check_product() # Verifica a licença do ArcGIS
  tabela <- arc.open(tabela_nome) # Abre a tabela shapefile
  df <- arc.data2sp(df = tabela) # Converte a tabela em um dataframe

  # Verifica se existe a coluna 'nm_parcela'
  if ("nm_parcela" %in% colnames(df)) {
    # Verifica a existência de talhões
    if (length(unique(df$talhao)) > 0) {
      # Cria a nova coluna 'contador' com a lógica de contagem
      df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)

      # Filtra apenas as linhas onde 'contador' é 1
      df <- df[df$contador != 0, ]

      # Escreve o dataframe atualizado de volta no arquivo shapefile
      arc.write(tabela_nome, df, overwrite = TRUE)
    } else {
      stop("Nenhum talhão encontrado na tabela.")
    }
  } else {
    stop("A coluna 'nm_parcela' não existe na tabela.")
  }
}

alocar_parcelas("piracicaba_talhão.shp")