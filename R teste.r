if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
  install.packages("arcgisbinding", repos="https://r.esri.com")
}

library(arcgisbinding)
arc.check_product()

alocar_parcelas <- function(tabela_nome) {
  arc.check_product()
  
  # Abrir a tabela no ArcGIS
  tabela <- arc.open(tabela_nome)
  print(tabela)
  
  # Ler a tabela mantendo a geometria
  df <- arc.select(tabela, fields = "*", where = NULL)
  print(nrow(df))
  
  # Verificar se a coluna 'NM_PARCELA' existe e tem dados
  if ("NM_PARCELA" %in% colnames(df) && nrow(df) > 0) {
    df$nm_parcela <- as.numeric(as.character(df$NM_PARCELA))
    
    # Criar um filtro baseado na coluna NM_PARCELA
    df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
    df_filtrado <- df[df$contador != 0, ]
    
    # Verificar se há dados após o filtro
    if (nrow(df_filtrado) == 0) {
      stop("Após o filtro, não há linhas restantes no dataframe.")
    }
    
    # Converter de volta para um objeto espacial antes de salvar
    df_filtrado$Shape <- df$Shape[df$contador != 0]  # Recuperando geometria original
    arc.write(tabela_nome, df_filtrado, overwrite = TRUE)
    
  } else {
    stop("A coluna 'NM_PARCELA' não existe ou está vazia.")
  }
}

# Executar a função
alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
