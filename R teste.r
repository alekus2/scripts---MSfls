if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
  install.packages("arcgisbinding", repos="https://r.esri.com")
}
library(arcgisbinding)
arc.check_product()
alocar_parcelas <- function(tabela_nome) {
  arc.check_product()
  tabela <- arc.open(tabela_nome)
  df <- arc.select(tabela)
  if ("NM_PARCELA" %in% colnames(df) && nrow(df) > 0) {
    df$nm_parcela <- as.numeric(as.character(df$NM_PARCELA))
  } else {
    stop("A coluna 'NM_PARCELA' não existe ou está vazia.")
  }
  df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
  df <- df[df$contador != 0, ]
  if (nrow(df) == 0) {
    stop("Após o filtro, não há linhas restantes no dataframe.")
  }
      df_spatial <- arc.data2sp(df)
      arc.write(tabela_nome, df_spatial, overwrite = TRUE)
    } else {
      stop("Nenhum talhão encontrado na tabela.")
    }
   else {
    stop("A coluna 'nm_parcela' não existe na tabela.")
  }

alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")

