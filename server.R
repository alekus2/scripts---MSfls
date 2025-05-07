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
    req(input$db_host, input$db_port, input$db_service,
        input$db_user, input$db_pwd)
    con <- dbConnect(odbc(),
                     Driver   = "Oracle",
                     Server   = input$db_host,
                     UID      = input$db_user,
                     PWD      = input$db_pwd,
                     Port     = input$db_port,
                     SVC      = input$db_service)
    tbls <- dbListTables(con)
    tl <- grep("talhao", tbls, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table",
                      choices = tl,
                      selected = tl[1])
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
    output$recomend_text <- renderText({
      req(input$recomend)
      paste("Upload de recomendação:", input$recomend$name)
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
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste("Forma:", input$forma_parcela,
            "| Tipo:", input$tipo_parcela,
            "| Distância mínima:", input$distancia_minima)
    })
  })

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

  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      files <- utils::unzip(input$parc_exist$datapath, exdir = tempdir())
      shp2 <- grep("\\.shp$", files, ignore.case = TRUE, value = TRUE)
      req(length(shp2) == 1, "Não encontrou .shp válido para parcelas existentes")
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
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(p) {
        progress$set(value = p, message = paste0(p, "% concluído"))
      }
    )
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        rows_ipc <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        n_s30    <- round(length(rows_ipc) * 0.3)
        sel      <- sample(rows_ipc, n_s30)
        result$TIPO_ATUAL[sel] <- "S30"
        result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
      for (idx in unique(result$Index)) {
        dt      <- result[result$Index == idx, ]
        cnt_s30 <- sum(dt$TIPO_ATUAL == "S30")
        needed  <- ifelse(nrow(dt) >= 2, 2, 1) - cnt_s30
        if (needed > 0) {
          more_idx <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
          sel2     <- sample(more_idx, needed)
          result$TIPO_ATUAL[sel2] <- "S30"
        }
        result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
    }
    result$STATUS[result$TIPO_ATUAL == "S30"] <- "ATIVA"
    values$result_points <- result
    showNotification(
      "Parcelas geradas com sucesso!",
      type     = "message",
      duration = 10
    )
  })

  output$index_filter <- renderUI({
    req(values$result_points)
    selectInput("selected_index", "Selecione o talhão:", choices = unique(values$result_points$Index))
  })

  observeEvent(input$gerar_novamente, {
    req(values$result_points, input$selected_index)
    sel <- input$selected_index
    new_base <- values$result_points %>% filter(Index != sel)
    shape_sel <- shape() %>% filter(Index == sel)
    result2 <- process_data(
      shape_sel, parc_exist_path(),
      forma_parcela(), tipo_parcela(),
      distancia_minima(), intensidade_amostral(),
      function(p) cat(">> progresso (regerar):", p, "\n")
    )
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result2$Index)) {
        rows_ipc <- which(result2$Index == idx & result2$TIPO_ATUAL == "IPC")
        n_s30    <- round(length(rows_ipc) * 0.3)
        sel      <- sample(rows_ipc, n_s30)
        result2$TIPO_ATUAL[sel] <- "S30"
        result2$STATUS[result2$Index == idx & result2$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
      for (idx in unique(result2$Index)) {
        dt      <- result2[result2$Index == idx, ]
        cnt_s30 <- sum(dt$TIPO_ATUAL == "S30")
        needed  <- ifelse(nrow(dt) >= 2, 2, 1) - cnt_s30
        if (needed > 0) {
          more_idx <- which(result2$Index == idx & result2$TIPO_ATUAL == "IPC")
          sel2     <- sample(more_idx, needed)
          result2$TIPO_ATUAL[sel2] <- "S30"
        }
        result2$STATUS[result2$Index == idx & result2$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
    }
    result2$STATUS[result2$TIPO_ATUAL == "S30"] <- "ATIVA"
    values$result_points <- bind_rows(new_base, result2)
    showNotification(
      "Parcelas regeneradas com sucesso!",
      type     = "message",
      duration = 10
    )
  })

  indexes <- reactive({ unique(values$result_points$Index) })
  current_index <- reactiveVal(1)

  observeEvent(input$proximo, {
    idxs <- indexes()
    ni   <- current_index() + 1
    if (ni > length(idxs)) ni <- 1
    current_index(ni)
    updateSelectInput(session, "selected_index", selected = idxs[ni])
  })

  observeEvent(input$anterior, {
    idxs <- indexes()
    pi   <- current_index() - 1
    if (pi < 1) pi <- length(idxs)
    current_index(pi)
    updateSelectInput(session, "selected_index", selected = idxs[pi])
  })

  output$download_result <- downloadHandler(
    filename = function() {
      ts <- format(Sys.time(), "%d-%m-%y_%H.%M")
      paste0("parcelas_", tipo_parcela(), "_", ts, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      ts             <- format(Sys.time(), "%d-%m-%y_%H.%M")
      temp_dir       <- tempdir()
      shapefile_dir  <- file.path(temp_dir, paste0("parcelas_", tipo_parcela(), "_", ts))
      unlink(shapefile_dir, recursive = TRUE, force = TRUE)
      dir.create(shapefile_dir, showWarnings = FALSE)
      shp_base       <- paste0("parcelas_", tipo_parcela(), "_", ts)
      shp_path       <- file.path(shapefile_dir, paste0(shp_base, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      files_to_zip   <- list.files(shapefile_dir, pattern = paste0("^", shp_base, "\\.(shp|shx|dbf|prj|cpg|qpj)$"), full.names = TRUE)
      zip::zipr(zipfile = file, files = files_to_zip, root = shapefile_dir)
    },
    contentType = "application/zip"
  )

  output$plot <- renderPlot({
    req(values$result_points, input$selected_index)
    shp_sel <- shape() %>% filter(Index == input$selected_index)
    req(nrow(shp_sel) > 0)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)
    area_ha <- as.numeric(st_area(shp_sel)) / 10000
    num_rec <- ceiling(area_ha / as.numeric(input$intensidade_amostral))
    if (num_rec < 2) num_rec <- 2
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
