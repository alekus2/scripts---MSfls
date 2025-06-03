# TABELA C
pivot_c <- df_final %>%
  pivot_wider(
    id_cols    = c("chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"),
    names_from = NM_COVA_ORDENADO,
-   values_from= Ht_media,
-   values_fill= 0
+   values_from= Ht_media,
+   values_fill= list(.default = 0)
  )

# …  

# TABELA D
pivot_d <- df_final %>%
  mutate(Ht3 = Ht_media^3) %>%
  pivot_wider(
    id_cols    = c("chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"),
    names_from = NM_COVA_ORDENADO,
-   values_from= Ht3,
-   values_fill= 0
+   values_from= Ht3,
+   values_fill= list(.default = 0)
  )
