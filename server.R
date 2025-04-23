library(shiny)

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
        paste0("Upload de parcelas existentes não realizado.")
      }
    })
    
    output$confirmation <- renderText({
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste("Forma Parcela:", input$forma_parcela, "Tipo Parcela:", input$tipo_parcela, "Distância Mínima:", input$distancia_minima)
    })
  })
  
  forma_parcela <- reactive({
    input$forma_parcela
  })
  
  tipo_parcela <- reactive({
    input$tipo_parcela
  })
  
  distancia_minima <- reactive({
    input$distancia_minima
  })
  
  intensidade_amostral <- reactive({
    input$intensidade_amostral
  })
  
  shape_path <- reactive({
    req(input$shape)
    shape_zip <- unzip(input$shape$datapath, exdir = tempdir())
    grep(shape_zip, pattern = ".shp$", value = TRUE)
  })
  
  shape <- reactive({
    req(shape_path())
    shp <- st_read(shape_path())
    
    if(input$shape_input_pergunta_arudek == 0) {
      shp <- shp %>%
        rename(ID_PROJETO := !!input$mudar_nome_arudek_projeto,
               TALHAO := !!input$mudar_nome_arudek_talhao,
               CICLO := !!input$mudar_nome_arudek_ciclo,
               ROTACAO := !!input$mudar_nome_arudek_rotacao)
    }
    
    shp <- shp %>%
      mutate(ID_PROJETO = str_pad(ID_PROJETO, 4, pad = 0),
             TALHAO = str_pad(TALHAO, 3, pad = 0))
    
    return(shp)
  })
  
  parc_exist_path <- reactive({
    if(input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      parc_exist_zip <- unzip(input$parc_exist$datapath, exdir = tempdir())
      grep(parc_exist_zip, pattern = ".shp$", value = TRUE)
    } else {
      paste0("data/parc.shp")
    }
  })
  
  recomend <- reactive({
    if(input$recomendacao_pergunta_upload == 1) {
      req(input$recomend)
      recomends <- read.csv2(input$recomend$datapath) %>% 
        mutate(Projeto = str_pad(Projeto, 4, pad = 0),
               Talhao = str_pad(Talhao, 3, pad = 0),
               Index = paste(Projeto, Talhao, sep = "")) %>%
        rename(Num.parc = N, ID_PROJETO = Projeto, TALHAO = Talhao)
      return(recomends) 
    } else {
      req(shape(), input$recomend_intensidade)
      shape <- shape() %>% st_make_valid()
      
      recomends <- shape %>% 
        group_by(ID_PROJETO, TALHAO) %>%
        summarise(Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade)))) %>%
        mutate(Num.parc = ifelse(as.numeric(Num.parc) < 2, 2, Num.parc),
               Index = paste0(ID_PROJETO, TALHAO)) %>%
        select(ID_PROJETO, TALHAO, Num.parc, Index) %>%
        as.data.frame() %>%
        select(-geometry)
      
      return(recomends)
    }
  })
  
  progress_percentage <- reactiveVal(0)
  values <- reactiveValues(result_points = NULL, process_complete = FALSE)
  
  observeEvent(input$gerar_parcelas, {
    session$sendCustomMessage("hide_completed", message = "")
    
    result <- process_data(
      shape(),
      recomend(),
      parc_exist_path(),
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(percent) {
        session$sendCustomMessage("update_progress", percent)
      }
    )
    
    if(input$lancar_sobrevivencia == 1){
      unique_indexes <- unique(result$Index)
      
      for (idx in unique_indexes) {
        idx_rows <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(idx_rows) * 0.3)
        s30_idx <- sample(idx_rows, s30_count)
        
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result[result$TIPO_ATUAL == "IPC" & result$Index == idx,]$STATUS <- "DESATIVADA"
      }
      
      for(i in unique(result$Index)) {
        dt_aux <- result[result$Index == i, ]
        
        s30_counts <- sum(dt_aux$TIPO_ATUAL == "S30")
        
        if (nrow(dt_aux) >= 2 && s30_counts < 2) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind = TRUE)
          if (length(idx_rows) >= 2 - s30_counts) {
            s30_idx <- sample(idx_rows, 2 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        } else if (nrow(dt_aux) < 2 && s30_counts < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind = TRUE)
          if (length(idx_rows) >= 1 - s30_counts) {
            s30_idx <- sample(idx_rows, 1 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        }
        result[result$TIPO_ATUAL == "IPC" & result$Index == i,]$STATUS <- "DESATIVADA"
      }
    }
    
    result[result$TIPO_ATUAL == "S30",]$STATUS <- "ATIVA"
    values$result_points <- result
    session$sendCustomMessage("show_completed", message = "")
  })
  
  output$index_filter <- renderUI({
    req(recomend())
    aux <- recomend()
    
    selectInput("selected_index", "Select Index:", choices = unique(aux$Index))
  })
  
  observeEvent(input$gerar_novamente, {
    selected_index <- input$selected_index
    values$result_points <- values$result_points %>% 
      mutate(Index = paste0(PROJETO, TALHAO)) %>% 
      filter(Index != selected_index)
    
    session$sendCustomMessage("hide_completed", message = "")
    shape_selected <- shape() %>%
      mutate(Index = paste0(ID_PROJETO, TALHAO)) %>% 
      filter(Index == selected_index)
    
    recomend_selected <- recomend() %>% 
      mutate(Index = paste0(ID_PROJETO, TALHAO)) %>%
      filter(Index == selected_index)
    
    result <- process_data(
      shape_selected,
      recomend_selected,
      parc_exist_path(),
      forma_parcela(),
      tipo_parcela(),
      distancia_minima(),
      intensidade_amostral(),
      function(percent) {
        session$sendCustomMessage("update_progress", percent)
      }
    )
    
    if(input$lancar_sobrevivencia == 1){
      unique_indexes <- unique(result$Index)
      
      for (idx in unique_indexes) {
        idx_rows <- which(result$Index == idx & result$TIPO_ATUAL == "IPC")
        s30_count <- round(length(idx_rows) * 0.3)
        s30_idx <- sample(idx_rows, s30_count)
        
        result$TIPO_ATUAL[s30_idx] <- "S30"
        result[result$TIPO_ATUAL == "IPC" & result$Index == idx,]$STATUS <- "DESATIVADA"
      }
      
      for(i in unique(result$Index)) {
        dt_aux <- result[result$Index == i, ]
        
        s30_counts <- sum(dt_aux$TIPO_ATUAL == "S30")
        
        if (nrow(dt_aux) >= 2 && s30_counts < 2) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind = TRUE)
          if (length(idx_rows) >= 2 - s30_counts) {
            s30_idx <- sample(idx_rows, 2 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        } else if (nrow(dt_aux) < 2 && s30_counts < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind = TRUE)
          if (length(idx_rows) >= 1 - s30_counts) {
            s30_idx <- sample(idx_rows, 1 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        }
        result[result$TIPO_ATUAL == "IPC" & result$Index == i,]$STATUS <- "DESATIVADA"
      }
    }
    
    result[result$TIPO_ATUAL == "S30",]$STATUS <- "ATIVA"
    values$result_points <- rbind(values$result_points, result) 
    session$sendCustomMessage("show_completed", message = "")
  })
  
  indexes <- reactive({
    unique(recomend()$Index)
  })
  
  current_index <- reactiveVal(1)
  
  observeEvent(input$proximo, {
    indexes_list <- indexes()
    next_index <- current_index() + 1
    if (next_index > length(indexes_list)) {
      next_index <- 1
    }
    current_index(next_index)
    updateSelectInput(session, "selected_index", selected = indexes_list[next_index])
  })
  
  observeEvent(input$anterior, {
    indexes_list <- indexes()
    prev_index <- current_index() - 1
    if (prev_index < 1) {
      prev_index <- length(indexes_list)
    }
    current_index(prev_index)
    updateSelectInput(session, "selected_index", selected = indexes_list[prev_index])
  })
  
  output$plot <- renderPlot({
    req(values$result_points, input$selected_index, shape())
    selected_index <- input$selected_index
    result_aux <- values$result_points
    shape_aux <- shape()
    shape_aux <- st_transform(shape_aux, 31982)
    
    shape_aux$Index <- paste0(shape_aux$ID_PROJETO, shape_aux$ITALHAO)
    shape_filtrado <- shape_aux %>% dplyr::filter(Index == selected_index)
    points_df <- result_aux %>% dplyr::filter(Index == selected_index)
    
    num_parc_title <- shape_filtrado %>% 
      dplyr::group_by(ID_PROJETO, ID_TALHAO) %>%
      dplyr::summarise(Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade)))) %>%
      dplyr::mutate(Num.parc = ifelse(as.numeric(Num.parc) < 2, 2, Num.parc),
                    Index = paste0(ID_PROJETO, TALHAO)) %>%
      dplyr::pull(Num.parc)
    
    area_titulo <- round(sum(st_area(shape_filtrado)) / 10000, 2)
    
    ggplot() + 
      geom_sf(data = shape_filtrado) + 
      theme_bw() +
      geom_sf(data = points_df %>% dplyr::filter(!is.na(LATITUDE)), aes(geometry = geometry)) + 
      theme(legend.position = "none") +
      ggtitle(paste0("Área (ha): ", area_titulo, "\nNum de Parcelas:", num_parc_title))
  })
  
  output$download_result <- downloadHandler(
    filename = function() {
      now <- Sys.time()
      data_str <- format(now, "%d-%m-%y_%H.%M")
      paste0("parcelas_", data_str, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      temp_dir <- tempdir()
      now <- Sys.time()
      data_str <- format(now, "%d-%m-%y_%H.%M")
      shapefile_dir <- file.path(temp_dir, paste0("parcelas_", data_str))
      dir.create(shapefile_dir)
      shapefile_path <- file.path(shapefile_dir, "parcelas.shp")
      st_write(values$result_points, dsn = shapefile_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      shapefile_files <- list.files(
        path = shapefile_dir,
        pattern = "parcelas\\.(shp|shx|dbf|prj|cpg|qpj)$",
        full.names = TRUE
      )
      zip::zipr(zipfile = file, files = shapefile_files, root = shapefile_dir)
    },
    contentType = "application/zip"
  )
  
}
