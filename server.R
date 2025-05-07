library(shiny)
library(sf)
library(DBI)
library(odbc)
library(stringr)
library(dplyr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {

  observeEvent(input$db_connect, {
    req(input$db_host, input$db_port, input$db_service, input$db_user, input$db_pwd)
    con <- dbConnect(odbc(),
                     Driver = "Oracle",
                     Server = input$db_host,
                     UID    = input$db_user,
                     PWD    = input$db_pwd,
                     Port   = input$db_port,
                     SVC    = input$db_service)
    tbls <- dbListTables(con)
    tl   <- grep("talhao", tbls, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table", choices = tl, selected = tl[1])
    session$userData$db_con <- con
  })

  output$db_layer_selector <- renderUI({
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })

  observeEvent(input$confirmar, {
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
    req(input$data_source)
    if (input$data_source == "upload") {
      req(input$shape)
      tmpdir <- file.path(tempdir(), tools::file_path_sans_ext(basename(input$shape$name)))
      unlink(tmpdir, recursive = TRUE, force = TRUE)
      dir.create(tmpdir, showWarnings = FALSE)
      unzip(input$shape$datapath, exdir = tmpdir)
      shp_files <- list.files(tmpdir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
      req(length(shp_files) >= 1)
      shppath <- shp_files[1]
      shp <- st_read(shppath, quiet = TRUE)
    } else {
      req(session$userData$db_con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      shp <- st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
    }
    validate(need(inherits(shp, "sf") && nrow(shp) > 0, "Erro na leitura do shapefile"))
    if (!is.null(input$shape_input_pergunta_arudek) &&
        input$shape_input_pergunta_arudek == 0) {
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

  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      tmpdir2 <- file.path(tempdir(), tools::file_path_sans_ext(basename(input$parc_exist$name)))
      unlink(tmpdir2, recursive = TRUE, force = TRUE)
      dir.create(tmpdir2, showWarnings = FALSE)
      unzip(input$parc_exist$datapath, exdir = tmpdir2)
      shp2 <- list.files(tmpdir2, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
      req(length(shp2) == 1)
      shp2
    } else {
      "data/parc.shp"
    }
  })

  values <- reactiveValues(result_points = NULL)

  observeEvent(input$gerar_parcelas, {
    progress <- Progress$new(session, min = 0, max = 100)
    on.exit(progress$close())
    result <- process_data(
      shape(),
      parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) progress$set(value = p, message = paste0(p, "% concluído"))
    )
    values$result_points <- result
    showNotification("Parcelas geradas com sucesso!", type = "message", duration = 10)
  })

  output$index_filter <- renderUI({
    req(values$result_points)
    selectInput("selected_index", "Selecione o talhão:", choices = unique(values$result_points$Index))
  })

  observeEvent(input$gerar_novamente, {
    req(values$result_points, input$selected_index)
    sel      <- input$selected_index
    new_base <- filter(values$result_points, Index != sel)
    result2  <- process_data(
      shape() %>% filter(Index == sel),
      parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) NULL
    )
    values$result_points <- bind_rows(new_base, result2)
    showNotification("Parcelas regeneradas com sucesso!", type = "message", duration = 10)
  })

  observeEvent(input$proximo, {
    idxs <- unique(values$result_points$Index)
    ni   <- which(idxs == input$selected_index) + 1
    if (ni > length(idxs)) ni <- 1
    updateSelectInput(session, "selected_index", selected = idxs[ni])
  })

  observeEvent(input$anterior, {
    idxs <- unique(values$result_points$Index)
    pi   <- which(idxs == input$selected_index) - 1
    if (pi < 1) pi <- length(idxs)
    updateSelectInput(session, "selected_index", selected = idxs[pi])
  })

  output$download_result <- downloadHandler(
    filename = function() {
      paste0("parcelas_", input$tipo_parcela, "_", format(Sys.time(), "%d-%m-%y_%H.%M"), ".zip")
    },
    content = function(file) {
      req(values$result_points)
      ts            <- format(Sys.time(), "%d-%m-%y_%H.%M")
      dir_shp       <- file.path(tempdir(), paste0("parcelas_", input$tipo_parcela, "_", ts))
      unlink(dir_shp, recursive = TRUE, force = TRUE)
      dir.create(dir_shp, showWarnings = FALSE)
      shp_base      <- paste0("parcelas_", input$tipo_parcela, "_", ts)
      shp_path      <- file.path(dir_shp, paste0(shp_base, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      files_to_zip  <- list.files(dir_shp, pattern = paste0("^", shp_base, "\\.(shp|shx|dbf|prj|cpg|qpj)$"), full.names = TRUE)
      zip::zipr(zipfile = file, files = files_to_zip, root = dir_shp)
    },
    contentType = "application/zip"
  )

  output$plot <- renderPlot({
    req(values$result_points, input$selected_index)
    shp_sel <- shape() %>% filter(Index == input$selected_index)
    req(nrow(shp_sel) > 0)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)
    area_ha <- as.numeric(st_area(shp_sel)) / 10000
    num_rec <- max(2, ceiling(area_ha / as.numeric(input$intensidade_amostral)))
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
