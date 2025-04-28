library(shiny)
library(sf)
library(dplyr)
library(ggplot2)

server <- function(input, output, session) {
  observeEvent(input$confirmar, {
    output$shape_text <- renderText({
      req(input$shape)
      paste("Upload realizado referente aos talhões:", input$shape$name)
    })
    output$recomend_text <- renderText({
      req(input$recomend)
      paste("Upload realizado referente a recomendação de parcelas:", input$recomend$name)
    })
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist)
        paste("Upload realizado referente as parcelas já existentes:", input$parc_exist$name)
      } else {
        "Upload de parcelas existentes não realizado."
      }
    })
    output$confirmation <- renderText({
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste("Forma Parcela:", input$forma_parcela, "Tipo Parcela:", input$tipo_parcela, "Distância Mínima:", input$distancia_minima)
    })
  })

  forma_parcela <- reactive({ input$forma_parcela })
  tipo_parcela <- reactive({ input$tipo_parcela })
  distancia_minima <- reactive({ input$distancia_minima })
  intensidade_amostral <- reactive({ input$intensidade_amostral })

  shape_path <- reactive({
    req(input$shape)
    unzip(input$shape$datapath, exdir = tempdir()) |> 
      grep(pattern = "\\.shp$", value = TRUE)
  })

  shape <- reactive({
    req(shape_path())
    st_read(shape_path()) |> 
      { if (input$shape_input_pergunta_arudek == 0) rename(., ID_PROJETO := !!input$mudar_nome_arudek_projeto, TALHAO := !!input$mudar_nome_arudek_talhao, CICLO := !!input$mudar_nome_arudek_ciclo, ROTACAO := !!input$mudar_nome_arudek_rotacao) else . } |>
      mutate(ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"), TALHAO = str_pad(TALHAO, 3, pad = "0"))
  })

  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      unzip(input$parc_exist$datapath, exdir = tempdir()) |> 
        grep(pattern = "\\.shp$", value = TRUE)
    } else {
      "data/parc.shp"
    }
  })

  recomend <- reactive({
    if (input$recomendacao_pergunta_upload == 1) {
      req(input$recomend)
      read.csv2(input$recomend$datapath) |>
        mutate(Projeto = str_pad(Projeto, 4, pad = "0"), Talhao = str_pad(Talhao, 3, pad = "0"), Index = paste0(Projeto, Talhao)) |>
        rename(Num.parc = N, ID_PROJETO = Projeto, TALHAO = Talhao)
    } else {
      req(shape(), input$recomend_intensidade)
      shape() |> 
        st_make_valid() |> 
        group_by(ID_PROJETO, TALHAO) |> 
        summarise(Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade))), .groups = "drop") |> 
        mutate(Num.parc = ifelse(Num.parc < 2, 2, Num.parc), Index = paste0(ID_PROJETO, TALHAO)) |> 
        select(ID_PROJETO, TALHAO, Num.parc, Index)
    }
  })

  values <- reactiveValues(result_points = NULL)

  observeEvent(input$gerar_parcelas, {
    session$sendCustomMessage("hide_completed", "")
    result <- process_data(shape(), recomend(), parc_exist_path(), forma_parcela(), tipo_parcela(), distancia_minima(), intensidade_amostral(), function(p) session$sendCustomMessage("update_progress", p))
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        idx_rows <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(idx_rows) * 0.3)
        s30_idx <- sample(idx_rows, s30_count)
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result[result$TIPO_ATUAL == "IPC" & result$Index == idx, "STATUS"] <- "DESATIVADA"
      }
      for (i in unique(result$Index)) {
        dt <- result[result$Index == i, ]
        s30c <- sum(dt$TIPO_ATUAL == "S30")
        if (nrow(dt) >= 2 && s30c < 2) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC")
          if (length(idx_rows) >= 2 - s30c) result$TIPO_ATUAL[sample(idx_rows, 2 - s30c)] <- "S30"
        } else if (nrow(dt) < 2 && s30c < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC")
          if (length(idx_rows) >= 1 - s30c) result$TIPO_ATUAL[sample(idx_rows, 1 - s30c)] <- "S30"
        }
        result[result$TIPO_ATUAL == "IPC" & result$Index == i, "STATUS"] <- "DESATIVADA"
      }
    }
    result[result$TIPO_ATUAL == "S30", "STATUS"] <- "ATIVA"
    values$result_points <- result
    session$sendCustomMessage("show_completed", "")
  })

  observeEvent(input$gerar_novamente, {
    sel <- input$selected_index
    values$result_points <- values$result_points |> filter(paste0(PROJETO, TALHAO) != sel)
    session$sendCustomMessage("hide_completed", "")
    shape_sel <- shape() |> mutate(Index = paste0(ID_PROJETO, TALHAO)) |> filter(Index == sel)
    recomend_sel <- recomend() |> filter(Index == sel)
    result <- process_data(shape_sel, recomend_sel, parc_exist_path(), forma_parcela(), tipo_parcela(), distancia_minima(), intensidade_amostral(), function(p) session$sendCustomMessage("update_progress", p))
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        idx_rows <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30c <- round(length(idx_rows) * 0.3)
        result$TIPO_ATUAL[sample(idx_rows, s30c)] <- "S30"
        result[result$TIPO_ATUAL == "IPC" & result$Index == idx, "STATUS"] <- "DESATIVADA"
      }
      for (i in unique(result$Index)) {
        dt <- result[result$Index == i, ]
        s30c <- sum(dt$TIPO_ATUAL == "S30")
        if (nrow(dt) >= 2 && s30c < 2) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC")
          result$TIPO_ATUAL[sample(idx_rows, 2 - s30c)] <- "S30"
        } else if (nrow(dt) < 2 && s30c < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC")
          result$TIPO_ATUAL[sample(idx_rows, 1 - s30c)] <- "S30"
        }
        result[result$TIPO_ATUAL == "IPC" & result$Index == i, "STATUS"] <- "DESATIVADA"
      }
    }
    result[result$TIPO_ATUAL == "S30", "STATUS"] <- "ATIVA"
    values$result_points <- bind_rows(values$result_points, result)
    session$sendCustomMessage("show_completed", "")
  })

  output$index_filter <- renderUI({
    req(recomend())
    selectInput("selected_index", "Select Index:", choices = unique(recomend()$Index))
  })

  observeEvent(input$proximo, {
    idxs <- unique(recomend()$Index)
    ci <- match(input$selected_index, idxs)
    ni <- if (ci == length(idxs)) 1 else ci + 1
    updateSelectInput(session, "selected_index", selected = idxs[ni])
  })

  observeEvent(input$anterior, {
    idxs <- unique(recomend()$Index)
    ci <- match(input$selected_index, idxs)
    pi <- if (ci == 1) length(idxs) else ci - 1
    updateSelectInput(session, "selected_index", selected = idxs[pi])
  })

  output$download_result <- downloadHandler(
    filename = function() {
      data_str <- format(Sys.time(), "%d-%m-%y_%H.%M")
      paste0("parcelas_", tipo_parcela(), "_", data_str, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      td <- tempdir()
      ds <- format(Sys.time(), "%d-%m-%y_%H.%M")
      sd <- file.path(td, paste0("parcelas_", ds))
      dir.create(sd)
      fp <- file.path(sd, paste0("parcelas_", tipo_parcela(), "_", ds, ".shp"))
      st_write(values$result_points, dsn = fp, driver = "ESRI Shapefile", delete_dsn = TRUE)
      zf <- list.files(sd, pattern = "parcelas\\.(shp|shx|dbf|prj|cpg|qpj)$", full.names = TRUE)
      zip::zipr(zipfile = file, files = zf, root = sd)
    },
    contentType = "application/zip"
  )

  output$plot <- renderPlot({
    req(values$result_points, input$selected_index, shape())
    sf_sel <- shape() |> st_transform(31982) |> mutate(Index = paste0(ID_PROJETO, TALHAO))
    shp <- filter(sf_sel, Index == input$selected_index)
    pts <- filter(values$result_points, Index == input$selected_index)
    num_rec <- shp |> summarise(n = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade)))) |> mutate(n = ifelse(n < 2, 2, n)) |> pull(n)
    area_ha <- round(sum(st_area(shp)) / 10000, 2)
    ggplot() +
      geom_sf(data = shp, fill = NA, color = "black") +
      geom_sf(data = pts, size = 2) +
      ggtitle(paste0("Recomendado: ", num_rec, " parc. (Área: ", area_ha, " ha)")) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })
}
