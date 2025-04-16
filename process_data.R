process_data <- function(shape, recomend, parc_exist_path, forma_parcela, 
                         tipo_parcela, distancia.minima, intensidade_amostral, 
                         update_progress) {
  
  # Ler shapefile das parcelas existentes
  parc_exist <- st_read(parc_exist_path)
  
  # Transformar para o CRS desejado (31982)
  shape <- st_transform(shape, 31982)
  parc_exist <- st_transform(parc_exist, 31982)
  
  # Criar coluna de Index para as parcelas
  shape$Index <- paste0(shape$ID_PROJETO, shape$ID_TALHAO)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)
  
  # Definir distância de buffer
  buffer_distance <- -15
  
  # Inicializar lista para armazenar as geometrias processadas
  shapeb <- list()
  empty_indexes <- c()
  
  # Loop para aplicar buffer e filtrar geometrias vazias
  for (i in 1:nrow(shape)) {
    buffered <- st_buffer(shape[i, ], buffer_distance)
    if (st_is_empty(buffered)) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      shapeb[[i]] <- buffered
    }
  }
  
  # Remover índices de geometrias vazias
  if (!is.null(empty_indexes) && length(empty_indexes) > 0) {
    shapeb <- shapeb[-empty_indexes]
  }
  
  # Unir as geometrias processadas em um único objeto
  shapeb <- do.call("rbind", shapeb)
  
  # Lista para armazenar os pontos gerados
  result_points <- list()
  completed_poly_idx <- 0
  
  # Contabilizar o número total de polígonos a processar
  total_poly_idx <- length(unique(shapeb$Index))
  
  # Loop para processar cada polígono
  for (poly_idx in unique(shapeb$Index)) {
    
    # Filtrar polígono específico
    poly <- shapeb[shapeb$Index == poly_idx, ]
    subgeoms <- split_subgeometries(poly)
    
    # Loop para processar cada subgeometria
    for (i in 1:nrow(subgeoms)) {
      sg <- subgeoms[i, ]
      sg_area <- as.numeric(st_area(sg))
      
      # Se a subgeometria for muito pequena, ignora
      if (sg_area < 400) {
        next
      }
      
      # Filtrar pontos ativos dentro do polígono
      active_points_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx, ]
      active_points <- st_intersection(st_geometry(active_points_all), st_geometry(sg))
      
      if (sg_area >= 400 & sg_area <= 1000) {
        if (length(active_points) > 0) {
          next
        } else {
          # Gerar ponto central para subgeometria válida
          cell.point <- st_centroid(st_geometry(sg))
          
          # Criar buffer de acordo com a área da subgeometria
          conf.point <- st_buffer(cell.point, dist = sqrt(400 / pi))
          conf.point <- st_intersection(conf.point, sg) %>% st_sf()
          
          points2 <- st_sf(data.frame(
            Area = sg_area,
            Index = poly_idx,
            PROJETO = poly$ID_PROJETO,
            TALHAO = poly$ID_TALHAO,
            CICLO = poly$CICLO,
            ROTACAO = poly$ROTACAO,
            STATUS = "ATIVA",
            FORMA = forma_parcela, 
            TIPO_INSTA = tipo_parcela,
            TIPO_ATUAL = tipo_parcela, 
            DATA = Sys.Date(),
            DATA_ATUAL = Sys.Date(),
            COORD_X = st_coordinates(cell.point)[1],
            COORD_Y = st_coordinates(cell.point)[2]
          ), geometry = st_geometry(cell.point))
          
          result_points[[paste(poly_idx, i, sep = "-")]] <- points2
        }
      } else {
        # Caso a subgeometria tenha área maior que 1000 m², utiliza uma grade (grid)
        # Cálculo do número de parcelas baseado na recomendação e intensidade amostral:
        num_parc_recom <- as.numeric(recomend[recomend$Index == poly_idx, "Num.parc"])
        num_parc_desejado <- round(num_parc_recom * as.numeric(intensidade_amostral))
        
        # Calcular a área da subgeometria em hectares (1 ha = 10.000 m²)
        sg_area_ha <- sg_area / 10000
        # Número máximo de parcelas possíveis dado a área disponível e a intensidade (cada parcela consome "intensidade_amostral" hectares)
        max_possible_plots <- floor(sg_area_ha / as.numeric(intensidade_amostral))
        
        if(max_possible_plots < num_parc_desejado) {
          warning(paste("Talhão", poly_idx, "não é suficiente para a intensidade amostral desejada (", intensidade_amostral, "ha).",
                        "Máximo de parcelas possíveis:", max_possible_plots))
          num_parc <- max_possible_plots
        } else {
          num_parc <- num_parc_desejado
        }
        
        # Criar uma grade de células para o polígono
        d <- 2 * sqrt(400 / pi) 
        grid <- st_make_grid(sg, cellsize = c(d, d), what = "polygons", square = TRUE)
        grid <- st_intersection(grid, sg) %>% st_sf()
        grid$area.grid <- round(as.numeric(st_area(grid)))
        grid <- grid %>% dplyr::filter(area.grid >= round(d^2))
        
        if(nrow(grid) == 0) {
          next
        }
        
        # Garantir que não selecione mais células que o grid possua
        num_parc <- min(num_parc, nrow(grid))
        
        # Selecionar aleatoriamente as células da grade
        indices_grid <- sample(1:nrow(grid), num_parc)  
        grid_selecionado <- grid[indices_grid, ]
        
        points_list <- list()
        for (j in 1:nrow(grid_selecionado)) {
          cell <- grid_selecionado[j, ]
          active_points_cell <- st_intersection(st_geometry(active_points), st_geometry(cell))
          
          if (length(active_points_cell) == 0) {
            cell.point <- st_centroid(st_geometry(cell))
            area_vector <- as.numeric(st_area(cell))
            index_vector <- rep(poly_idx, length(area_vector))
            
            points_list[[j]] <- st_sf(data.frame(
              Area = area_vector,
              Index = index_vector,
              PROJETO = poly$ID_PROJETO,
              TALHAO = poly$ID_TALHAO,
              CICLO = poly$CICLO,
              ROTACAO = poly$ROTACAO,
              STATUS = "ATIVA",
              FORMA = forma_parcela, 
              TIPO_INSTA = tipo_parcela,
              TIPO_ATUAL = tipo_parcela,
              DATA = Sys.Date(),
              DATA_ATUAL = Sys.Date(),
              COORD_X = st_coordinates(cell.point)[1],
              COORD_Y = st_coordinates(cell.point)[2]
            ), geometry = st_geometry(cell.point))
          } else {
            next
          }
        }
        if (length(points_list) > 0) {
          points2 <- do.call("rbind", points_list)
          result_points[[paste(poly_idx, i, sep = "-")]] <- points2
        }
      }
      completed_poly_idx <- completed_poly_idx + 1
    }
    
    # Atualizar progresso
    progress_percent <- round((completed_poly_idx / total_poly_idx) * 100, 2)
    update_progress(progress_percent)
  }
  
  # Combinar todos os pontos gerados
  result_points <- do.call("rbind", result_points)
  
  # Processar numeração de parcelas
  parcelasinv <- parc_exist %>%
    dplyr::group_by(PROJETO) %>%
    dplyr::summarise(numeracao = max(PARCELAS[PARCELAS < 500]),
                     numeracao2 = max(PARCELAS)) %>% as.data.frame()
  
  # Ajustar numeração conforme o tipo de parcela
  if (tipo_parcela %in% c("IFQ6", "IFQ12", "S30", "S90", "PP")) {
    parcelasinv <- parcelasinv %>%
      dplyr::mutate(numeracao.inicial = if_else(numeracao == 499, numeracao2 + 1, numeracao + 1)) %>%
      dplyr::select(PROJETO, numeracao.inicial)
  } else {
    parcelasinv <- parcelasinv %>%
      dplyr::mutate(numeracao.inicial = dplyr::if_else(numeracao < 500, 501, numeracao)) %>%
      dplyr::select(PROJETO, numeracao.inicial)
  }
  
  # Juntar numeração inicial ao resultado final
  result_points <- result_points %>%
    dplyr::left_join(parcelasinv, by = "PROJETO") %>%
    dplyr::mutate(numeracao.inicial = tidyr::replace_na(numeracao.inicial, 1)) %>%
    dplyr::group_by(PROJETO) %>%
    dplyr::mutate(PARCELAS = dplyr::row_number() - 1 + dplyr::first(numeracao.inicial)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-Area, -numeracao.inicial)
  
  return(result_points)
}
