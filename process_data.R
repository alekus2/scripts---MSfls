  bind_rows(result_pts) %>%
    group_by(INDEX_) %>%
    mutate(
      NM_PARCELA = row_number(),
      MES_PROG = paste(
        month(DATA_PLANT, label = TRUE, abbr = FALSE),
        format(DATA_PLANT, "%Y"),
        sep = "-"
      )
    ) %>%
    ungroup() %>%
    select(
      # mantém todas as colunas até INDEX_
      ID_PROJETO, PROJETO, TALHAO, REGIME, ESPACAMENT, MATERIAL_G,
      DATA_PLANT, CHAVE, POINT_X, POINT_Y, INDEX_,
      # aqui as suas duas colunas novas
      NM_PARCELA, MES_PROG,
      # a seguir o STATUS e o restante
      STATUS, FORMA, CICLO, ROTACAO, TIPO_INSTA, TIPO_ATUAL,
      DATA_ATUAL, AREA_HA, geometry
    )
