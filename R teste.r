> alocar_parcelas("Pto_Parcelas_QLD.shp")
Error in alocar_parcelas("Pto_Parcelas_QLD.shp") : 
  could not find function "alocar_parcelas"

library(arcgisbinding)
alocar_parcelas <- function(tabela_nome) {
  arc.check_product()
  tabela <- arc.open(tabela_nome)
  df <- arc.data2sp(df = tabela)
  if ("nm_parcela" %in% colnames(df)) {
    if (length(unique(df$talhao)) > 0) {
      df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
      df <- df[df$contador != 0, ]
      arc.write(tabela_nome, df, overwrite = TRUE)
    } else {
      stop("Nenhum talhão encontrado na tabela.")
    }
  } else {
    stop("A coluna 'nm_parcela' não existe na tabela.")
  }
}

alocar_parcelas("Pto_Parcelas_QLD.shp")
