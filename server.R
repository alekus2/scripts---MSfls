library(shiny)
library(sf)
library(DBI)
library(odbc)
library(dplyr)
library(stringr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {
  
  ## 1) Conexão ArcSDE Oracle via TNS alias e OS-auth/UID-PWD
  observeEvent(input$db_connect, {
    req(input$db_tns)
    if (isTRUE(input$db_os_auth)) {
      con <- dbConnect(odbc(),
                       Driver    = "Oracle",
                       Dbq       = input$db_tns,
                       OSAuthent = "YES")
    } else {
      req(input$db_user, input$db_pwd)
      con <- dbConnect(odbc(),
                       Driver = "Oracle",
                       Dbq    = input$db_tns,
                       UID    = input$db_user,
                       PWD    = input$db_pwd)
    }
    tables <- dbListTables(con)
    talhao_tables <- grep("talhao", tables, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table",
                      choices  = talhao_tables,
                      selected = talhao_tables[1])
    session$userData$db_con     <- con
    session$userData$db_os_auth <- input$db_os_auth
  })
  
  output$db_layer_selector <- renderUI({
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })
  
  ## 2) Mensagens de confirmação
  observeEvent(input$confirmar, {
    output$shape_text <- renderText({
      if (input$data_source == "upload") {
        req(input$shape); paste("Upload realizado referente aos talhões:", input$shape$name)
      } else {
        req(input$db_table); paste("Conectado à camada de talhões:", input$db_table)
      }
    })
    output$recomend_text <- renderText({
      req(input$recomend); paste("Upload realizado referente a recomendação de parcelas:", input$recomend$name)
    })
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist); paste("Upload realizado referente às parcelas já existentes:", input$parc_exist$name)
      } else "Upload de parcelas existentes não realizado."
    })
    output$confirmation <- renderText({
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste("Forma Parcela:", input$forma_parcela,
            "| Tipo Parcela:", input$tipo_parcela,
            "| Distância Mínima:", input$distancia_minima)
    })
  })
  
  ## 3) Reactives simples
  forma_parcela        <- reactive({ input$forma_parcela })
  tipo_parcela         <- reactive({ input$tipo_parcela })
  distancia_minima     <- reactive({ input$distancia_minima })
  intensidade_amostral <- reactive({ input$intensidade_amostral })
  
  ## 4) Leitura do shape: upload ZIP OU ArcSDE TNS alias
  shape <- reactive({
    if (input$data_source == "upload") {
      req(input$shape)
      shp_zip  <- unzip(input$shape$datapath, exdir = tempdir())
      shp_file <- grep("\\.shp$", shp_zip, value = TRUE)
      st_read(shp_file, quiet = TRUE)
    } else {
      con_ok <- session$userData$db_con
      req(con_ok, input$db_table)
      st_read(dsn = input$db_tns, layer = input$db_table, quiet = TRUE)
    }
  })
  
  ## 5) Parcela existentes
  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      parc_zip <- unzip(input$parc_exist$datapath, exdir = tempdir())
      grep("\\.shp$", parc_zip, value = TRUE)
    } else "data/parc.shp"
  })
  
  ## 6) Recomendação de parcelas
  recomend <- reactive({
    if (input$recomendacao_pergunta_upload == 1) {
      req(input$recomend)
      read.csv2(input$recomend$datapath) %>%
        mutate(
          Projeto = str_pad(Projeto, 4, pad = "0"),
          Talhao  = str_pad(Talhao,  3, pad = "0"),
          Index   = paste0(Projeto, Talhao)
        ) %>%
        rename(Num.parc = N, ID_PROJETO = Projeto, TALHAO = Talhao)
    } else {
      req(shape(), input$recomend_intensidade)
      shape() %>%
        st_make_valid() %>%
        group_by(ID_PROJETO, TALHAO) %>%
        summarise(
          Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade))),
          .groups  = "drop"
        ) %>%
        mutate(
          Num.parc = ifelse(Num.parc < 2, 2, Num.parc),
          Index   = paste0(ID_PROJETO, TALHAO)
        ) %>%
        select(ID_PROJETO, TALHAO, Num.parc, Index)
    }
  })
  
  ## 7) Geração de parcelas e sobrevivência
  values <- reactiveValues(result_points = NULL)
  observeEvent(input$gerar_parcelas, {
    session$sendCustomMessage("hide_completed", "")
    result <- process_data(
      shape(), recomend(), parc_exist_path(),
      forma_parcela(), tipo_parcela(), distancia_minima(), intensidade_amostral(),
      function(p) session$sendCustomMessage("update_progress", p)
    )
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        rows_ipc <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(rows_ipc) * 0.3)
        s30_idx   <- sample(rows_ipc, s30_count)
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
        dt_aux     <- result[result$Index == idx, ]
        s30_actual <- sum(dt_aux$TIPO_ATUAL == "S30")
        if (nrow(dt_aux) >= 2 && s30_actual < 2) {
          need <- 2 - s30_actual
          more <- sample(which(dt_aux$TIPO_ATUAL == "IPC"), need)
          result$TIPO_ATUAL[which(result$Index == idx)[more]] <- "S30"
          result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
        }
      }
    }
    result$STATUS[result$TIPO_ATUAL == "S30"] <- "ATIVA"
    values$result_points <- result
    session$sendCustomMessage("show_completed", "")
  })
  
  ## 8) Filtro de índice
  output$index_filter <- renderUI({
    req(recomend())
    selectInput("selected_index", "Selecione o talhão:", choices = unique(recomend()$Index))
  })
  
  ## 9) Gerar novamente
  observeEvent(input$gerar_novamente, {
    sel <- input$selected_index
    values$result_points <- values$result_points %>% filter(Index != sel)
    shape_sel    <- shape()   %>% mutate(Index = paste0(ID_PROJETO, TALHAO)) %>% filter(Index == sel)
    recomend_sel <- recomend()%>% mutate(Index = paste0(ID_PROJETO, TALHAO)) %>% filter(Index == sel)
    result <- process_data(
      shape_sel, recomend_sel, parc_exist_path(),
      forma_parcela(), tipo_parcela(), distancia_minima(), intensidade_amostral(),
      function(p) session$sendCustomMessage("update_progress", p)
    )
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        rows_ipc <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(rows_ipc) * 0.3)
        s30_idx   <- sample(rows_ipc, s30_count)
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
        dt_aux     <- result[result$Index == idx, ]
        s30_actual <- sum(dt_aux$TIPO_ATUAL == "S30")
        if (nrow(dt_aux) >= 2 && s30_actual < 2) {
          need <- 2 - s30_actual
          more <- sample(which(dt_aux$TIPO_ATUAL == "IPC"), need)
          result$TIPO_ATUAL[which(result$Index == idx)[more]] <- "S30"
          result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
        }
      }
    }
    result$STATUS[result$TIPO_ATUAL == "S30"] <- "ATIVA"
    values$result_points <- bind_rows(values$result_points, result)
    session$sendCustomMessage("show_completed", "")
  })
  
  ## 10) Navegação
  indexes       <- reactive(unique(recomend()$Index))
  current_index <- reactiveVal(1)
  observeEvent(input$proximo, {
    idxs <- indexes(); ni <- current_index() + 1; if (ni > length(idxs)) ni <- 1
    current_index(ni); updateSelectInput(session, "selected_index", selected = idxs[ni])
  })
  observeEvent(input$anterior, {
    idxs <- indexes(); pi <- current_index() - 1; if (pi < 1) pi <- length(idxs)
    current_index(pi); updateSelectInput(session, "selected_index", selected = idxs[pi])
  })
  
  ## 11) Download
  output$download_result <- downloadHandler(
    filename = function() {
      dt <- format(Sys.time(), "%d-%m-%y_%H.%M")
      paste0("parcelas_", tipo_parcela(), "_", dt, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      dt <- format(Sys.time(), "%d-%m-%y_%H.%M")
      out_dir <- tempfile(pattern = paste0("parcelas_", tipo_parcela(), "_", dt, "_"))
      dir.create(out_dir)
      shp_path <- file.path(out_dir, paste0("parcelas_", tipo_parcela(), "_", dt, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      shp_files <- list.files(out_dir, pattern = "\\.(shp|shx|dbf|prj|cpg|qpj)$", full.names = TRUE)
      zip::zipr(zipfile = file, files = shp_files, root = out_dir)
    },
    contentType = "application/zip"
  )
  
  ## 12) Plotagem
  output$plot <- renderPlot({
    req(values$result_points, input$selected_index, shape())
    sf_sel <- shape() %>% st_transform(31982) %>% mutate(Index = paste0(ID_PROJETO, TALHAO))
    shp_sel <- sf_sel %>% filter(Index == input$selected_index)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)
    area_ha <- as.numeric(shp_sel$AREA_HA[1])
    num_rec <- ceiling(area_ha / as.numeric(input$intensidade_amostral)); if (num_rec < 2) num_rec <- 2
    ggplot() +
      geom_sf(data = shp_sel, fill = NA, color = "black") +
      geom_sf(data = pts_sel, size = 2) +
      ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                     " (Área: ", round(area_ha, 2), " ha)")) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })
}

shinyApp(ui, server)
