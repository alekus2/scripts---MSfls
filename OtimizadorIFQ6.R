# Primeiro, verifique se a coluna de área existe
area_col <- df_cadastro %>% select(contains("AREA")) %>% names() %>% first()

# Certifique-se de que a coluna existe antes de tentar fazer a junção
if (!is.null(area_col) && area_col %in% names(df_cadastro)) {
  # Realize a junção
  df_res <- df_final %>%
    left_join(
      df_cadastro %>% select(Index, !!sym(area_col)), # Use !!sym() para referenciar a coluna selecionada
      by = "Index"
    ) %>%
    rename(Area_ha = !!sym(area_col)) %>% # Renomeie a coluna para Area_ha
    mutate(Area_ha = replace_na(Area_ha, 0)) # Substitua NAs por 0 ou outro valor desejado
} else {
  stop("A coluna de área não foi encontrada em df_cadastro.")
}