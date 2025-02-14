library(arcgisbinding)

alocar_parcelas <- function(tabela_nome) {
  arc.check_product()
  tabela <- arc.open(tabela_nome)
  df <- arc.data2sp(df = tabela)

  df$CONTADOR <- ifelse(df$nm_parcela < 3, 1, ifelse(df$nm_parcela %% 2 != 0, 1, 0))

  df <- df[df$CONTADOR != 0, ]

  arc.write(tabela_nome, df, overwrite = TRUE)
}

alocar_parcelas("piracicaba_talhão.shp")

> source("f:\\Qualidade_Florestal\\02- MATO GROSSO DO SUL\\11- Administrativo $
*** Please call arc.check_product() to define a desktop license.
Error in .call_proxy("dataset.open", .Object, path) : cannot open dataset
