# 8) leitura de cadastro e criação de “Index”
df_cadastro <- read_excel(cadastro_path, sheet = 1, col_types = "text") %>%
  mutate(Index = paste0(`Id Projeto`, Talhao))

df_final <- df_final %>%
  mutate(
    Index = paste0(CD_PROJETO, CD_TALHAO),
    Index = if_else(
      str_detect(Index, "-\\d{2}$"),
      Index,
      if_else(
        str_detect(Index, "-\\d$"),
        str_replace(Index, "-(\\d)$", "-0\\1"),
        paste0(Index, "-01")
      )
    )
  )


area_col <- df_cadastro %>%
  select(contains("AREA")) %>%
  names() %>%
  first()

df_res <- df_final %>%
  left_join(
    df_cadastro %>% select(Index, all_of(area_col)),
    by = "Index"
  ) %>%
  rename(Area_ha = !!sym(area_col)) %>%
  mutate(Area_ha = replace_na(Area_ha, "")) %>%
  rename(
    nm_parcela      = NM_PARCELA,
    nm_area_parcela = NM_AREA_PARCELA
  )
