library(shiny)
library(sf)
library(DBI)
library(odbc)
library(dplyr)
library(stringr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {
  
  ## 1) Conexão ArcSDE Oracle e seleção de camada "talhao"
  observeEvent(input$db_connect, {
    req(input$db_host, input$db_port, input$db_service, input$db_user, input$db_pwd)
    con <- dbConnect(odbc(),
                     Driver   = "Oracle",            # ajuste conforme seu driver ODBC
                     Server   = input$db_host,
                     UID      = input$db_user,
                     PWD      = input$db_pwd,
                     Port     = input$db_port,
                     SVC      = input$db_service)
    # lista tabelas contendo "talhao"
    tables <- dbListTables(con)
    talhao_tables <- grep("talhao", tables, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table",
                      choices  = talhao_tables,
                      selected = talhao_tables[1])
    session$userData$db_con <- con
  })
  
  output$db_layer_selector <- renderUI({
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })
  
  
  ## 2) Mensagens de confirmação ao clicar "Confirmar"
  observeEvent(input$confirmar, {
    output$shape_text <- renderText({
      if (input$data_source == "upload") {
        req(input$shape)
        paste("Upload realizado referente aos talhões:", input$shape$name)
      } else {
        req(input$db_table)
        paste("Conectado à camada de talhões:", input$db_table)
      }
    })
    
    output$recomend_text <- renderText({
      req(input$recomend)
      paste("Upload realizado referente a recomendação de parcelas:", input$recomend$name)
    })
    
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist)
        paste("Upload realizado referente às parcelas já existentes:", input$parc_exist$name)
      } else {
        "Upload de parcelas existentes não realizado."
      }
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
  
  
  ## 4) Leitura do shape: upload ZIP OU ArcSDE
  shape <- reactive({
    if (input$data_source == "upload") {
      req(input$shape)
      # extrai ZIP para tempdir
      shp_zip <- unzip(input$shape$datapath, exdir = tempdir())
      shp_path <- grep("\\.shp$", shp_zip, value = TRUE)
      shp <- st_read(shp_path, quiet = TRUE)
    } else {
      # ArcSDE via GDAL/OCI
      con <- session$userData$db_con
      req(con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      shp <- st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
    }
    
    # renomeia campos se necessário
    if (input$shape_input_pergunta_arudek == 0) {
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
    }
    
    # padroniza comprimentos
    shp %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO,     3, pad = "0")
      )
  })
  
  
  ## 5) Parcela existentes
  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      parc_zip <- unzip(input$parc_exist$datapath, exdir = tempdir())
      grep("\\.shp$", parc_zip, value = TRUE)
    } else {
      "data/parc.shp"
    }
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
        rename(
          Num.parc   = N,
          ID_PROJETO = Projeto,
          TALHAO     = Talhao
        )
    } else {
      req(shape(), input$recomend_intensidade)
      shape() %>%
        st_make_valid() %>%
        group_by(ID_PROJETO, TALHAO) %>%
        summarise(
          Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade))),
          .groups = "drop"
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
      shape(),
      recomend(),
      parc_exist_path(),
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(p) session$sendCustomMessage("update_progress", p)
    )
    
    if (input$lancar_sobrevivencia == 1) {
      for (idx in unique(result$Index)) {
        rows_ipc <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(rows_ipc) * 0.3)
        s30_idx   <- sample(rows_ipc, s30_count)
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result$STATUS[result$Index == idx & result$TIPO_ATUAL == "IPC"] <- "DESATIVADA"
        
        # garante ao menos 2 S30 se possível
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
  
  
  ## 8) UI para filtro de índice
  output$index_filter <- renderUI({
    req(recomend())
    selectInput("selected_index", "Selecione o talhão:", choices = unique(recomend()$Index))
  })
  
  
  ## 9) Gerar novamente (mesma lógica do gerar_parcelas, mas para um só índice)
  observeEvent(input$gerar_novamente, {
    selected_index <- input$selected_index
    # remove o índice já plotado
    values$result_points <- values$result_points %>%
      filter(Index != selected_index)
    
    shape_sel   <- shape()   %>% mutate(Index = paste0(ID_PROJETO, TALHAO)) %>% filter(Index == selected_index)
    recomend_sel<- recomend()%>% mutate(Index = paste0(ID_PROJETO, TALHAO)) %>% filter(Index == selected_index)
    
    result <- process_data(
      shape_sel,
      recomend_sel,
      parc_exist_path(),
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(p) session$sendCustomMessage("update_progress", p)
    )
    
    if (input$lancar_sobrevivencia == 1) {
      # mesma lógica de sobrevivência...
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
  
  
  ## 10) Navegação entre índices
  indexes      <- reactive(unique(recomend()$Index))
  current_index<- reactiveVal(1)
  
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
  
  
  ## 11) Download das parcelas
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
      shp_path <- file.path(out_dir,
                            paste0("parcelas_", tipo_parcela(), "_", dt, ".shp"))
      st_write(values$result_points, dsn = shp_path,
               driver = "ESRI Shapefile", delete_dsn = TRUE)
      shp_files <- list.files(out_dir,
                              pattern = "\\.(shp|shx|dbf|prj|cpg|qpj)$",
                              full.names = TRUE)
      zip::zipr(zipfile = file, files = shp_files, root = out_dir)
    },
    contentType = "application/zip"
  )
  
  
  ## 12) Plotagem
  output$plot <- renderPlot({
    req(values$result_points, input$selected_index, shape())
    sf_sel <- shape() %>%
      st_transform(31982) %>%
      mutate(Index = paste0(ID_PROJETO, TALHAO))
    shp_sel <- filter(sf_sel, Index == input$selected_index)
    pts_sel <- filter(values$result_points, Index == input$selected_index)
    
    # calcula recomendações
    area_ha <- as.numeric(shp_sel$AREA_HA[1])
    num_rec <- ceiling(area_ha / as.numeric(input$intensidade_amostral))
    num_rec <- ifelse(num_rec < 2, 2, num_rec)
    
    ggplot() +
      geom_sf(data = shp_sel, fill = NA, color = "black") +
      geom_sf(data = pts_sel, size = 2) +
      ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                     " (Área: ", round(area_ha, 2), " ha)")) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })
  
}
