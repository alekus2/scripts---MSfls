library(shiny)
library(sf)
library(DBI)
library(odbc)
library(stringr)
library(dplyr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {
  message("Server iniciado")

  observeEvent(input$db_connect, {
    message("observeEvent: db_connect iniciado")
    req(input$db_host, input$db_port, input$db_service, input$db_user, input$db_pwd)
    message("Credenciais recebidas: ",
            input$db_host, ":", input$db_port, "/", input$db_service,
            " user=", input$db_user)
    con <- dbConnect(odbc(),
                     Driver = "Oracle",
                     Server = input$db_host,
                     UID    = input$db_user,
                     PWD    = input$db_pwd,
                     Port   = input$db_port,
                     SVC    = input$db_service)
    message("Conexão estabelecida: ", class(con))
    tbls <- dbListTables(con)
    message("Tabelas encontradas: ", length(tbls))
    tl <- grep("talhao", tbls, ignore.case = TRUE, value = TRUE)
    message("Camadas de talhão: ", paste(tl, collapse = ", "))
    updateSelectInput(session, "db_table", choices = tl, selected = tl[1])
    session$userData$db_con <- con
    message("Conexão salva em userData")
  })

  output$db_layer_selector <- renderUI({
    message("renderUI: db_layer_selector")
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })

  observeEvent(input$confirmar, {
    message("observeEvent: confirmar")
    output$shape_text <- renderText({
      if (input$data_source == "upload") {
        req(input$shape)
        paste("Upload realizado shapefile:", input$shape$name)
      } else {
        req(input$db_table)
        paste("Conectado à camada:", input$db_table)
      }
    })
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist)
        paste("Upload parcelas históricas:", input$parc_exist$name)
      } else {
        "Parcelas existentes não informadas."
      }
    })
    output$confirmation <- renderText({
      paste("Forma:", input$forma_parcela,
            "| Tipo:", input$tipo_parcela,
            "| Distância mínima:", input$distancia_minima)
    })
  })

  shape <- reactive({
    message("shape(): inicio")
    req(input$data_source)
    message("shape(): data_source =", input$data_source)
    shp <- if (input$data_source == "upload") {
      req(input$shape)
      message("shape(): lendo shapefile do upload")
      zp      <- unzip(input$shape$datapath, exdir = tempdir())
      shpfile <- grep("\\.shp$", zp, value = TRUE)
      shp_read <- st_read(shpfile, quiet = TRUE)
      message("shape(): upload lido, class=", class(shp_read), ", n=", nrow(shp_read))
      shp_read
    } else {
      message("shape(): lendo shapefile do DB")
      req(session$userData$db_con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      shp_read <- st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
      message("shape(): DB lido, class=", class(shp_read), ", n=", nrow(shp_read))
      shp_read
    }
    validate(need(inherits(shp, "sf") && nrow(shp) > 0, "Erro na leitura do shapefile"))
    message("shape(): before rename, names=", paste(names(shp), collapse = ", "))
    if (!is.null(input$shape_input_pergunta_arudek) &&
        input$shape_input_pergunta_arudek == 0) {
      message("shape(): renomeando colunas")
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
      message("shape(): depois do rename, names=", paste(names(shp), collapse = ", "))
    }
    shp_proj <- st_transform(shp, 31982)
    message("shape(): reprojetado para 31982, n=", nrow(shp_proj))
    shp_final <- shp_proj %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO,     3, pad = "0"),
        Index      = paste0(ID_PROJETO, TALHAO)
      )
    message("shape(): colunas criadas, names=", paste(names(shp_final), collapse = ", "))
    shp_final
  })

  parc_exist_path <- reactive({
    message("parc_exist_path(): inicio")
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      files <- utils::unzip(input$parc_exist$datapath, exdir = tempdir())
      shp2 <- grep("\\.shp$", files, ignore.case = TRUE, value = TRUE)
      req(length(shp2) == 1)
      message("parc_exist_path(): shapefile histórico =", shp2)
      shp2
    } else {
      message("parc_exist_path(): usando default data/parc.shp")
      "data/parc.shp"
    }
  })

  values <- reactiveValues(result_points = NULL)

  observeEvent(input$gerar_parcelas, {
    message("observeEvent: gerar_parcelas iniciado")
    progress <- Progress$new(session, min = 0, max = 100); on.exit(progress$close())
    result <- process_data(
      shape(),
      parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) {
        progress$set(value = p, message = paste0(p, "% concluído"))
      }
    )
    message("gerar_parcelas: process_data retornou, linhas=", nrow(result))
    values$result_points <- result
    showNotification("Parcelas geradas com sucesso!", type = "message", duration = 10)
  })

  output$index_filter <- renderUI({
    message("renderUI: index_filter")
    req(values$result_points)
    selectInput("selected_index", "Selecione o talhão:", choices = unique(values$result_points$Index))
  })

  observeEvent(input$gerar_novamente, {
    message("observeEvent: gerar_novamente iniciado")
    req(values$result_points, input$selected_index)
    sel <- input$selected_index
    message("gerar_novamente: selecionado Index =", sel)
    shape_sel <- shape() %>% filter(Index == sel)
    result2 <- process_data(
      shape_sel, parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) cat("regerar:", p, "\n")
    )
    message("gerar_novamente: process_data retornou, linhas=", nrow(result2))
    values$result_points <- bind_rows(
      filter(values$result_points, Index != sel),
      result2
    )
    showNotification("Parcelas regeneradas com sucesso!", type = "message", duration = 10)
  })

  indexes <- reactive({ unique(values$result_points$Index) })
  current_index <- reactiveVal(1)

  observeEvent(input$proximo, {
    message("observeEvent: proximo")
    idxs <- indexes(); ni <- current_index() + 1
    if (ni > length(idxs)) ni <- 1
    current_index(ni)
    updateSelectInput(session, "selected_index", selected = idxs[ni])
  })

  observeEvent(input$anterior, {
    message("observeEvent: anterior")
    idxs <- indexes(); pi <- current_index() - 1
    if (pi < 1) pi <- length(idxs)
    current_index(pi)
    updateSelectInput(session, "selected_index", selected = idxs[pi])
  })

  output$download_result <- downloadHandler(
    filename = function() {
      ts <- format(Sys.time(), "%d-%m-%y_%H.%M")
      paste0("parcelas_", input$tipo_parcela, "_", ts, ".zip")
    },
    content = function(file) {
      message("downloadHandler: iniciando download")
      req(values$result_points)
      ts <- format(Sys.time(), "%d-%m-%y_%H.%M")
      d <- file.path(tempdir(), paste0("parcelas_", input$tipo_parcela, "_", ts))
      unlink(d, recursive = TRUE); dir.create(d, showWarnings = FALSE)
      shp_base <- paste0("parcelas_", input$tipo_parcela, "_", ts)
      shp_path <- file.path(d, paste0(shp_base, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      files_to_zip <- list.files(d, pattern = paste0("^", shp_base, "\\.(shp|shx|dbf|prj|cpg|qpj)$"), full.names = TRUE)
      zip::zipr(zipfile = file, files = files_to_zip, root = d)
      message("downloadHandler: zip criado em ", file)
    },
    contentType = "application/zip"
  )

  output$plot <- renderPlot({
    message("renderPlot: inicio")
    req(values$result_points, input$selected_index)
    shp_sel <- shape() %>% filter(Index == input$selected_index)
    message("renderPlot: shp_sel class=", class(shp_sel), ", n=", nrow(shp_sel))
    req(nrow(shp_sel) > 0)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)
    area_ha <- as.numeric(st_area(shp_sel)) / 10000
    num_rec <- ceiling(area_ha / as.numeric(input$intensidade_amostral)); if (num_rec < 2) num_rec <- 2
    ggplot() +
      geom_sf(data = shp_sel, fill = NA, color = "#007E69", size = 1) +
      geom_sf(data = pts_sel, size = 2) +
      ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                     " (Área: ", round(area_ha, 2), " ha)")) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })
}

shinyApp(ui = ui, server = server)
