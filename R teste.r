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
 if ("NM_PARCELA" %in% colnames(df) && nrow(df) > 0) {
    df$nm_parcela <- as.numeric(as.character(df$NM_PARCELA))
} else {
    stop("A coluna 'NM_PARCELA' não existe ou está vazia.")
}
    
    # Verifica se existem talhões
    if ("talhao" %in% colnames(df) && length(unique(df$talhao)) > 0) {
      
      # Cria a nova coluna 'contador' com a lógica de contagem
      df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
df <- df[df$contador != 0, ]
if (nrow(df) == 0) {
    stop("Após o filtro, não há linhas restantes no dataframe.")
}
      
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

> if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
+   install.packages("arcgisbinding", repos="https://r.esri.com")
+ }
> if (!requireNamespace("arcgisbinding", quietly = TRUE)) {
+   install.packages("arcgisbinding", repos="https://r.esri.com")
+ }
> library(arcgisbinding)
*** Please call arc.check_product() to define a desktop license.
> arc.check_product()
product: ArcGIS Pro (12.9.5.32739)
license: Advanced
version: 1.0.1.311 
> alocar_parcelas <- function(tabela_nome) {
+   arc.check_product()
+   tabela <- arc.open(tabela_nome)
+   df <- arc.select(tabela)
+   if ("NM_PARCELA" %in% colnames(df)) {
+     df$nm_parcela <- as.numeric(as.character(df$nm_parcela))
+     if ("CD_USO_SOL" %in% colnames(df) && length(unique(df$talhao)) > 0) {
+       df$contador <- ifelse(df$nm_parcela %% 2 != 0, 1, 0)
+       df <- df[df$contador != 0, ]
+       df_spatial <- arc.data2sp(df)
+       arc.write(tabela_nome, df_spatial, overwrite = TRUE)
+     } else {
+       stop("Nenhum talhão encontrado na tabela.")
+     }
+   } else {
+     stop("A coluna 'nm_parcela' não existe na tabela.")
+   }
+ }
> alocar_parcelas("Pto_Qualidade_Parcelas_Piracicaba.shp")
Error in `$<-.data.frame`(`*tmp*`, "nm_parcela", value = numeric(0)) :
replacement has 0 rows, data has 196
