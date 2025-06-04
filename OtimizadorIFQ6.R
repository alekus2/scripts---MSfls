# 9) Construção da tabela C conforme lógica do Python
cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
            "nm_parcela", "nm_area_parcela")

# Verifique se as colunas existem antes de selecionar
df_pivot <- df_res %>%
  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>%
  pivot_wider(
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht_media,
    values_fill = 0
  )

# Verifique se existem NA nas colunas que você vai usar
if (anyNA(df_pivot[cols0])) {
  stop("Existem valores ausentes nas colunas necessárias para a operação.")
}