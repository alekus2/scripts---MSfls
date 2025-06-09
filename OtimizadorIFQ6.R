df_res <- df_res %>%
  mutate(Ht_media = as.numeric(Ht_media))  # Conversão garantida

cols0 <- c("Area_ha", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO",
           "NM_PARCELA", "NM_AREA_PARCELA")

df_pivot <- df_res %>%
  select(any_of(cols0), NM_COVA_ORDENADO, Ht_media) %>%
  pivot_wider(
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht_media,
    values_fill = list(Ht_media = 0)
  )
