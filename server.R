shape <- reactive({
  req(input$data_source)
  shp <- if (input$data_source == "upload") {
    req(input$shape)
    zp      <- unzip(input$shape$datapath, exdir = tempdir())
    shpfile <- grep("\\.shp$", zp, value = TRUE)
    st_read(shpfile, quiet = TRUE)
  } else {
    req(session$userData$db_con, input$db_table)
    dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                   input$db_user, input$db_pwd,
                   input$db_host, input$db_port,
                   input$db_service)
    st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
  }

  # valida se as colunas existem antes de renomear ou mutar
  if (!("ID_PROJETO" %in% names(shp) &&
        "TALHAO"     %in% names(shp))) {
    validate(
      need(
        input$shape_input_pergunta_arudek == 0,
        "Shape não tem colunas ID_PROJETO e TALHAO.  
        Selecione ‘Outro’ e informe os nomes corretos antes de continuar."
      )
    )
  }

  if (isTRUE(input$shape_input_pergunta_arudek == 0)) {
    shp <- shp %>%
      rename(
        ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
        TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
        CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
        ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
      )
  }

  shp %>%
    st_transform(31982) %>%
    mutate(
      ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
      TALHAO     = str_pad(TALHAO,     3, pad = "0"),
      Index      = paste0(ID_PROJETO, TALHAO)
    )
})
