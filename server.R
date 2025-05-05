library(shiny)
library(sf)
library(stringr)
library(dplyr)
library(zip)
library(ggplot2)

server <- function(input, output, session) {
  # Confirmation texts
  observeEvent(input$confirmar, {
    output$shape_text <- renderText({
      req(input$shape)
      paste("Upload talhões:", input$shape$name)
    })
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist)
        paste("Upload parcelas existentes:", input$parc_exist$name)
      } else {
        "Upload de parcelas existentes não realizado."
      }
    })
    output$confirmation <- renderText({
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste(
        "Forma:", input$forma_parcela,
        "Tipo:", input$tipo_parcela,
        "Distância mínima:", input$distancia_minima
      )
    })
  })

  # Reactives for inputs
  forma_parcela        <- reactive({ input$forma_parcela })
  tipo_parcela         <- reactive({ input$tipo_parcela })
  distancia_minima     <- reactive({ input$distancia_minima })
  intensidade_amostral <- reactive({ input$intensidade_amostral })

  # Unzip and read shape
  shape_path <- reactive({
    req(input$shape)
    files <- utils::unzip(input$shape$datapath, exdir = tempdir())
    shp <- grep("\\.shp$", files, ignore.case = TRUE, value = TRUE)
    req(length(shp) == 1, "Não encontrou nenhum .shp válido")
    shp
  })
  shape <- reactive({
    shp_file <- shape_path()
    shp <- st_read(shp_file, quiet = TRUE)
    if (input$shape_input_pergunta_arudek == 0) {
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
    }
    shp %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO, 3, pad = "0")
      )
  })

  # Unzip and read existing parcels shapefile (or default)
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

  # Generate parcels
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
    # opcional: lançar sobrevivência
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
    showNotification("Parcelas geradas com sucesso!", type = "message", duration = 10)
  })

  # UI for selecting index, with default
  output$index_filter <- renderUI({
    req(values$result_points)
    ix <- unique(values$result_points$Index)
    selectInput(
      "selected_index", "Selecione o talhão:",
      choices  = ix,
      selected = ix[1]
    )
  })

  # Regenerate for a single talhão
  observeEvent(input$gerar_novamente, {
    req(values$result_points, input$selected_index)
    sel <- input$selected_index
    new_base <- values$result_points %>% filter(Index != sel)
    shape_sel <- shape() %>%
      mutate(Index = paste0(ID_PROJETO, TALHAO)) %>%
      filter(Index == sel)
    result2 <- process_data(
      shape_sel,
      parc_exist_path(),
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(p) cat(">> progresso (regerar):", p, "\n")
    )
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result2$Index)) {
        rows_ipc <- which(result2$Index == idx & result2$TIPO_ATUAL == "IPC")
        n_s30    <- round(length(rows_ipc) * 0.3)
        sel2     <- sample(rows_ipc, n_s30)
        result2$TIPO_ATUAL[sel2] <- "S30"
        result2$STATUS[result2$Index == idx & result2$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
      for (idx in unique(result2$Index)) {
        dt      <- result2[result2$Index == idx, ]
        cnt_s30 <- sum(dt$TIPO_ATUAL == "S30")
        needed  <- ifelse(nrow(dt) >= 2, 2, 1) - cnt_s30
        if (needed > 0) {
          more_idx <- which(result2$Index == idx & result2$TIPO_ATUAL == "IPC")
          sel3     <- sample(more_idx, needed)
          result2$TIPO_ATUAL[sel3] <- "S30"
        }
        result2$STATUS[result2$Index == idx & result2$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
      }
    }
    result2$STATUS[result2$TIPO_ATUAL == "S30"] <- "ATIVA"
    values$result_points <- bind_rows(new_base, result2)
    showNotification("Parcelas regeneradas com sucesso!", type = "message", duration = 10)
  })

  # Navigation helpers (próximo/anterior)
  indexes       <- reactive({ unique(values$result_points$Index) })
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

  # Download handler
  output$download_result <- downloadHandler(
    filename = function() {
      ts <- format(Sys.time(), "%d-%m-%y_%H.%M")
      paste0("parcelas_", tipo_parcela(), "_", ts, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      ts            <- format(Sys.time(), "%d-%m-%y_%H.%M")
      temp_dir      <- tempdir()
      shapefile_dir <- file.path(temp_dir, paste0("parcelas_", tipo_parcela(), "_", ts))
      unlink(shapefile_dir, recursive = TRUE, force = TRUE)
      dir.create(shapefile_dir, showWarnings = FALSE)
      shp_base <- paste0("parcelas_", tipo_parcela(), "_", ts)
      shp_path <- file.path(shapefile_dir, paste0(shp_base, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      files_to_zip <- list.files(shapefile_dir, pattern = paste0("^", shp_base, "\\.(shp|shx|dbf|prj|cpg|qpj)$"), full.names = TRUE)
      zip::zipr(zipfile = file, files = files_to_zip, root = shapefile_dir)
    },
    contentType = "application/zip"
  )

  # Plot rendering, sempre mostrando polígono e pontos
  output$plot <- renderPlot({
    req(values$result_points, input$selected_index)

    sf_sel  <- shape() %>%
                 st_transform(31982) %>%
                 mutate(Index = paste0(ID_PROJETO, TALHAO))
    shp_sel <- sf_sel %>% filter(Index == input$selected_index)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)

    # Se não houver nada, exibe mensagem
    if (nrow(shp_sel) == 0 && nrow(pts_sel) == 0) {
      plot.new()
      title("Nenhum dado para o talhão selecionado")
      return()
    }

    # Converte área e intensidade
    area_ha <- as.numeric(shp_sel$AREA_HA[1])
    intens  <- as.numeric(input$intensidade_amostral)
    if (is.na(intens) || intens <= 0) {
      intens <- if (!is.na(area_ha) && area_ha > 0) area_ha / 2 else 1
    }

    # Calcula número recomendado, mínimo 2
    num_rec <- ceiling(area_ha / intens)
    if (is.na(num_rec) || num_rec < 2) num_rec <- 2

    # Monta plot
    p <- ggplot() +
      { if (nrow(shp_sel) > 0)
          geom_sf(data = shp_sel, fill = NA, color = "#007E69")
        else NULL } +
      { if (nrow(pts_sel) > 0)
          geom_sf(data = pts_sel, size = 2)
        else NULL } +
      ggtitle(sprintf(
        "Número de parcelas recomendadas: %d  (Área: %.2f ha)",
        num_rec, area_ha
      )) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))

    print(p)
  })
}
