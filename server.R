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
      paste("Forma Parcela:", input$forma_parcela, "Tipo Parcela:", input$tipo_parcela, "Distância Miníma: ", input$distancia_minima)
    })
  })
  
  grid_existente <- reactive({
  req(input$grid_existente)
  
  shp_path <- input$grid_existente$datapath[grepl(".shp$", input$grid_existente$name)]
  dir_path <- dirname(shp_path)
  shp_name <- input$grid_existente$name[grepl(".shp$", input$grid_existente$name)]
  shp_full <- file.path(dir_path, shp_name)
  
  st_read(shp_full, options = "ENCODING=UTF-8")
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
               ID_TALHAO := !!input$mudar_nome_arudek_talhao,
               CICLO := !!input$mudar_nome_arudek_ciclo,
               ROTACAO := !!input$mudar_nome_arudek_rotacao)
    }
    
    shp <- shp %>%
      mutate(ID_PROJETO = str_pad(ID_PROJETO, 4, pad = 0),
             ID_TALHAO = str_pad(ID_TALHAO, 3, pad = 0))
    
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
        rename(Num.parc = N, ID_PROJETO = Projeto, ID_TALHAO = Talhao)
      return(recomends) 
    } else {
      
      req(shape(), input$recomend_intensidade)
      shape <- shape() %>% st_make_valid()
      
      recomends <- shape %>% 
        group_by(ID_PROJETO, ID_TALHAO) %>%
        summarise(Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade)))) %>%
        mutate(Num.parc = ifelse(as.numeric(Num.parc) < 2, 2, Num.parc),
               Index = paste0(ID_PROJETO, ID_TALHAO)) %>%
        select(ID_PROJETO, ID_TALHAO, Num.parc, Index) %>%
        as.data.frame() %>%
        select(-geometry)
      
      return(recomends)
    }
  })
  
  output$download_recomend <- downloadHandler(
    filename = function() {
      paste(input$download_recomend_name, ".csv", sep = "")
    },
    content = function(file) {
      write.csv2(recomend(), file, row.names = FALSE)
    },
    contentType = "text/csv"
  )
  
  
  progress_percentage <- reactiveVal(0)
  values <- reactiveValues(result_points = NULL, process_complete = FALSE)
  
  observeEvent(input$gerar_parcelas, {
    session$sendCustomMessage("hide_completed", message = "")
    
    
   
    result <- process_data(shape = shape(),
                          recomend = recomend(),
                          parc_exist_path = caminho_parc_exist(),
                          forma_parcela = input$formato,
                          tipo_parcela = input$tipo,
                          distancia.minima = input$distancia,
                          update_progress = function(percent) {session$sendCustomMessage("update_progress", percent)},
                          grid_existente = grid_existente())
    
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
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind=TRUE)
          if (length(idx_rows) >= 2 - s30_counts) {
            s30_idx <- sample(idx_rows, 2 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        } else if (nrow(dt_aux) < 2 && s30_counts < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind=TRUE)
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
      mutate( Index = paste0(ID_PROJETO, ID_TALHAO)) %>% 
      filter(Index == selected_index)
    
    recomend_selected <- recomend() %>% 
      mutate(Index = paste0(ID_PROJETO, ID_TALHAO)) %>%
      filter(Index == selected_index)
    
    result <- process_data(shape_selected, recomend_selected, parc_exist_path(), forma_parcela(), tipo_parcela(), distancia_minima(), function(percent) {
      session$sendCustomMessage("update_progress", percent)
    })
    
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
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind=TRUE)
          if (length(idx_rows) >= 2 - s30_counts) {
            s30_idx <- sample(idx_rows, 2 - s30_counts)
            result$TIPO_ATUAL[s30_idx] <- "S30"
          }
        } else if (nrow(dt_aux) < 2 && s30_counts < 1) {
          idx_rows <- which(result$Index == i & result$TIPO_ATUAL == "IPC", arr.ind=TRUE)
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
    
    shape_aux$Index <- paste0(shape_aux$ID_PROJETO, shape_aux$ID_TALHAO)
    shape_filtrado <- shape_aux %>% filter(Index == selected_index)
    points_df <- result_aux %>% filter(Index == selected_index)
    
    num_parc_title <- shape_filtrado %>% 
      group_by(ID_PROJETO, ID_TALHAO) %>%
      summarise(Num.parc = ceiling(sum(st_area(geometry)) / (10000 * as.numeric(input$recomend_intensidade)))) %>%
      mutate(Num.parc = ifelse(as.numeric(Num.parc) < 2, 2, Num.parc),
             Index = paste0(ID_PROJETO, ID_TALHAO)) %>%
      pull(Num.parc)
    
    area_titulo <- round(sum(st_area(shape_filtrado)) / 10000, 2)
    
    ggplot() + 
      geom_sf(aes(), data = shape_filtrado) + 
      geom_sf(aes(), data = points_df) + 
      custom_theme +
      ggtitle(paste0("NÃºmero de parcelas recomendado: ", num_parc_title, " (Ãrea: ", area_titulo, " ha)"))
  })
  
  output$download_result <- downloadHandler(
    filename = function() {
      paste0(input$download_name, ".zip")
    },
    content = function(file) {
      req(values$result_points)
      temp_dir <- tempdir()
      shapefile_name <- paste(input$download_name, ".shp", sep = "")
      shapefile_path <- file.path(temp_dir, shapefile_name)
      st_write(values$result_points, shapefile_path, "ESRI Shapefile")
      shapefile_files <- list.files(temp_dir, pattern = paste0(input$download_name, "\\..*"), full.names = TRUE)
      zip(file, shapefile_files)
    }
  )
  
}