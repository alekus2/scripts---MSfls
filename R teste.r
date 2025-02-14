# Carrega o pacote e verifica a licença do ArcGIS
if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
  install.packages("arcgisbinding", repos="https://r.esri.com")
}
library(arcgisbinding)
arc.check_product()

# Função para alocar parcelas
alocar_parcelas <- function(tabela_nome) {
  arc.check_product()
  
  # Abre a tabela shapefile
  tabela <- arc.open(tabela_nome)
  
  # Converte para um dataframe
  df <- arc.select(tabela)

  # Verifica se existe a coluna 'nm_parcela'
  if ("nm_parcela" %in% colnames(df)) {
    
    # Converte para numérico (evita erro com fatores)
    df$nm_parcela <- as.numeric(as.character(df$nm_parcela))
    
    # Verifica se existem talhões
    if ("talhao" %in% colnames(df) && length(unique(df$talhao)) > 0) {
      
      # Cria a nova coluna 'contador' com a lógica de contagem
      df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
      
      # Filtra apenas as linhas onde 'contador' é 1
      df <- df[df$contador != 0, ]
      
      # Converte de volta para um formato espacial, se necessário
      df_spatial <- arc.data2sp(df)
      
      # Escreve o dataframe atualizado no arquivo shapefile
      arc.write(tabela_nome, df_spatial, overwrite = TRUE)
      
    } else {
      stop("Nenhum talhão encontrado na tabela.")
    }
  } else {
    stop("A coluna 'nm_parcela' não existe na tabela.")
  }
}

# Executa a função
alocar_parcelas("Pto_Parcelas_QLD.shp")
