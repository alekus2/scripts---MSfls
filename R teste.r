library(arcgisbinding)

alocar_parcelas <- function(tabela_nome) {
  arc.check_product() # Verifica a licença do ArcGIS
  tabela <- arc.open(tabela_nome) # Abre a tabela shapefile
  df <- arc.data2sp(df = tabela) # Converte a tabela em um dataframe

  # Verifica se existe a coluna 'nm_parcela' e se os talhões existem
  if ("nm_parcela" %in% colnames(df)) {
    # Agrupa por talhão e conta o número de parcelas
    df_max <- aggregate(nm_parcela ~ talhao, data = df, FUN = max)
    colnames(df_max)[2] <- "max_parcelas"

    # Cria a nova coluna 'CONTADOR' com base na paridade da parcela
    df$CONTADOR <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)

    # Filtra apenas as linhas onde CONTADOR é 1
    df <- df[df$CONTADOR != 0, ]

    # Escreve a nova tabela no arquivo shapefile
    arc.write(tabela_nome, df, overwrite = TRUE)

    # Cria uma nova tabela chamada 'contador' com os dados desejados
    contador <- data.frame(talhao = df$talhao, contador = df$CONTADOR)
    arc.write("contador.shp", contador, overwrite = TRUE) # Salva a tabela contador

  } else {
    stop("A coluna 'nm_parcela' não existe na tabela.")
  }
}

alocar_parcelas("piracicaba_talhão.shp")