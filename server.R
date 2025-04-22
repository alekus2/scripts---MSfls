# server.R
library(shiny)
library(sf)
library(dplyr)
library(ggplot2)

# traz a função de process_data.R
source("process_data.R")

server <- function(input, output, session) {

  ## reactive paths e dados
  shape <- reactive({
    req(input$shape)
    shp_zip <- unzip(input$shape$datapath, exdir = tempdir())
    shp_file <- grep("\\.shp$", shp_zip, value=TRUE)
    shp <- st_read(shp_file, quiet=TRUE)
    if (input$shape_fmt == 0) {
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$col_projeto),
          TALHAO     = !!sym(input$col_talhao),
          CICLO      = !!sym(input$col_ciclo),
          ROTACAO    = !!sym(input$col_rotac)
        )
    }
    shp %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad="0"),
        TALHAO     = str_pad(TALHAO,     3, pad="0")
      )
  })

  parc_exist_path <- reactive({
    if (input$has_existentes == 1) {
      zipf <- unzip(input$parc_exist$datapath, exdir = tempdir())
      grep("\\.shp$", zipf, value=TRUE)
    } else {
      # path padrão se não houver
      "data/parc.shp"
    }
  })

  recomend <- reactive({
    if (input$has_recomend == 1) {
      req(input$recomend)
      rec <- read.csv2(input$recomend$datapath, stringsAsFactors=FALSE)
      rec %>%
        mutate(
          Projeto = str_pad(Projeto, 4, pad="0"),
          Talhao  = str_pad(Talhao,  3, pad="0"),
          Index   = paste0(Projeto, Talhao),
          Num.parc = as.integer(N)
        ) %>%
        select(ID_PROJETO=Projeto, TALHAO=Talhao, Num.parc, Index)
    } else {
      shp <- shape()
      shp <- st_make_valid(shp)
      shp %>%
        group_by(ID_PROJETO, TALHAO) %>%
        summarise(area_m2 = sum(st_area(geometry))) %>%
        ungroup() %>%
        mutate(
          Num.parc = ceiling((area_m2/10000) / as.numeric(input$recomend_intensidade)),
          Num.parc = pmax(Num.parc, 2),
          Index   = paste0(ID_PROJETO, TALHAO)
        ) %>%
        select(ID_PROJETO, TALHAO, Num.parc, Index)
    }
  })

  ## confirma uploads
  observeEvent(input$confirmar, {
    output$shape_text      <- renderText(paste("Shape:", input$shape$name))
    output$recomend_text   <- renderText({
      if (input$has_recomend==1) paste("Recomend:", input$recomend$name)
      else                   "Recomendação gerada internamente"
    })
    output$parc_exist_text <- renderText({
      if (input$has_existentes==1) paste("Parcelas exist.:", input$parc_exist$name)
      else                           "Nenhuma histórica fornecida"
    })
    output$confirmation    <- renderText({
      paste(
        "Forma:", input$forma_parcela,
        "| Tipo:", input$tipo_parcela,
        "| Intensidade (ha):", input$intensidade_amostral
      )
    })
  })

  ## geração e plot
  values <- reactiveValues(result = NULL)
  progress <- function(p) {
    session$sendCustomMessage("update_progress", p)
  }

  observeEvent(input$gerar_parcelas, {
    session$sendCustomMessage("hide_completed", "")
    vals <- process_data(
      shape(),
      recomend(),
      parc_exist_path(),
      input$forma_parcela,
      input$tipo_parcela,
      as.numeric(input$intensidade_amostral),
      progress
    )
    values$result <- vals
    session$sendCustomMessage("show_completed", "")
  })

  output$map_plot <- renderPlot({
    req(values$result)
    shp <- st_transform(shape(), 31982)
    idx <- paste0(shp$ID_PROJETO, shp$TALHAO)[1]
    pts <- values$result %>% filter(Index == idx)
    ggplot() +
      geom_sf(data = shp, fill = NA) +
      geom_sf(data = pts, aes(geometry = geometry), color="black") +
      theme_minimal() +
      labs(title = paste0("Índice: ", idx))
  })

  ## download
  output$download_result <- downloadHandler(
    filename = function() paste0(input$nome_arquivo, ".zip"),
    content = function(file) {
      tmp <- tempdir()
      shpf <- file.path(tmp, paste0(input$nome_arquivo, ".shp"))
      st_write(values$result, shpf, delete_layer=TRUE, quiet=TRUE)
      files <- list.files(tmp, pattern=input$nome_arquivo, full.names=TRUE)
      zip::zip(zipfile=file, files=files, flags = "-j")
    }
  )
}

shinyApp(ui, server)
