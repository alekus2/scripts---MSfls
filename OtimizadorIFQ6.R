# Definições de calc_metrics, codes e falhas aqui…

# 8) gera tabelas C e D
df_final <- df_final %>%
  mutate(
    Ht_media         = as.numeric(NM_ALTURA),
    Ht_media         = replace_na(Ht_media, 0),    # <— remove NAs
    NM_COVA_ORDENADO = NM_COVA,
    chave_stand      = paste(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
    dt_medicao1      = DT_INICIAL,
    equipe2          = CD_EQUIPE
  ) %>%
  select(-check_dup, -check_cd, -check_sqc)

# TABELA C
pivot_c <- df_final %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht_media,
    values_fill = list(.default = 0),
    values_fn   = mean
  )

# … calcula covas, met_c, conts, df_c …

# TABELA D
pivot_d <- df_final %>%
  mutate(
    Ht3 = Ht_media^3,
    Ht3 = replace_na(Ht3, 0)                   # <— remove NAs
  ) %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht3,
    values_fill = list(.default = 0),
    values_fn   = mean
  )

# … calcula met_d, df_d …
