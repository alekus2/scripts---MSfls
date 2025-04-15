process_data <- function(shape, recomend, parc_exist_path, forma_parcela, tipo_parcela, distancia.minima, update_progress) {
  
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
    if (st_is_empty(st_buffer(shape[i,], buffer_distance))) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      dt_aux <- st_buffer(shape[i,], buffer_distance)
      shapeb[[i]] <- dt_aux
    }
  }
  
  # Remover índices de geometrias vazias
  if(!is.null(empty_indexes)) {
    shapeb <- shapeb[-empty_indexes]
  }
  
  # Unir as geometrias processadas em um único objeto
  shapeb <- do.call("rbind", shapeb)
  
  # Lista para armazenar os pontos gerados
  result_points <- list()
  points2 <- NULL
  aux <- 1
  tempo <- 0
  
  # Contabilizar o número total de polígonos e o número de polígonos processados
  total_poly_idx <- length(unique(shapeb$Index)) 
  completed_poly_idx <- 0
  
  # Loop para processar cada polígono
  for (poly_idx in unique(shapeb$Index)) { 
    
    # Filtrar polígono específico
    poly <- shapeb[shapeb$Index == poly_idx,]
    subgeoms <- split_subgeometries(poly)
    
    # Loop para processar cada subgeometria
    for (i in 1:nrow(subgeoms)) {
      if(as.numeric(st_area(subgeoms[i,])) < 400) {
        next
      } else {
        sg <- subgeoms[i,]
        sg_area <- as.numeric(st_area(sg))
        
        # Filtrar pontos ativos dentro do polígono
        active_points_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx,]
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
            
            # Criar o ponto a ser adicionado ao resultado
            points2 <- st_sf(data.frame(Area = sg_area,
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
                                        COORD_Y = st_coordinates(cell.point)[2]),
                             geometry = st_geometry(cell.point))
          }
        } else {
          # Número de parcelas baseado na recomendação
          num_parc <- recomend[recomend$Index == poly_idx, "Num.parc"]
          
          # Ajustar número de parcelas com base na área da subgeometria
          if(nrow(subgeoms) > 1) { 
            num_parc <- num_parc + nrow(subgeoms)
            num_parc <- round(num_parc * (st_area(subgeoms) / st_area(poly)))
            num_parc <- as.numeric(num_parc)
            num_parc <- ifelse(num_parc < 1, 1, num_parc)
            num_parc <- num_parc[i]
            num_parc <- ifelse(num_parc >= recomend[recomend$Index == poly_idx, "Num.parc"],
                               recomend[recomend$Index == poly_idx, "Num.parc"],
                               num_parc)
          } else {
            num_parc <- num_parc
          }
          
          # Criar uma grade de células para o polígono
          d <- 2 * sqrt(400 / pi) 
          grid <- st_make_grid(sg, cellsize = c(d, d), what = "polygons", square = T)
          grid <- st_intersection(grid, sg) %>%  st_sf()
          grid$area.grid <- round(as.numeric(st_area(grid)))
          grid <- grid %>% filter(area.grid >= round(d^2))
          
          if(nrow(grid) == 0) {
            next
          }
          
          num_parc <- min(num_parc, nrow(grid))
          
          # Selecionar aleatoriamente as células da grade
          indices_grid <- sample(1:nrow(grid), num_parc)  
          grid_selecionado <- grid[indices_grid,]
          
          points_list <- list()
          for (j in 1:nrow(grid_selecionado)) {
            cell <- grid_selecionado[j,]
            active_points_cell <- st_intersection(st_geometry(active_points), st_geometry(cell))
            
            if (length(active_points_cell) == 0) {
              cell.point <- st_centroid(st_geometry(cell))
              
              area_vector <- as.numeric(st_area(cell))
              index_vector <- rep(poly_idx, length(area_vector))
              
              # Adicionar ponto à lista
              points_list[[j]] <- st_sf(data.frame(Area = area_vector,
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
                                                   COORD_Y = st_coordinates(cell.point)[2]),
                                        geometry = st_geometry(cell.point))
            } else {
              next
            }
          }
          points2 <- do.call("rbind", points_list)
        }
        
        # Adicionar pontos processados ao resultado
        result_points[[paste(poly_idx, i, sep = "-" )]] <- points2 
        completed_poly_idx <- completed_poly_idx + 1
      }
    }
    
    # Atualizar progresso
    progress_percent <- round((completed_poly_idx / total_poly_idx) * 100, 2)
    update_progress(progress_percent)
  }
  
  # Combinar todos os pontos gerados
  result_points <- do.call("rbind", result_points)
  
  # Processar numeracao de parcelas
  parcelasinv <- parc_exist %>%
    group_by(PROJETO) %>%
    dplyr::summarise(numeracao = max(PARCELAS[PARCELAS < 500]),
                     numeracao2 = max(PARCELAS)) %>% as.data.frame()
  
  # Ajustar numeracao conforme o tipo de parcela
  if (tipo_parcela %in% c("IFQ6", "IFQ12", "S30", "S90", "PP")) {
    parcelasinv <-  parcelasinv %>%
      mutate(numeracao.inicial = if_else(numeracao == 499, numeracao2 + 1, numeracao + 1)) %>%
      select(PROJETO, numeracao.inicial)
  } else {
    parcelasinv <- parcelasinv %>%
      mutate(numeracao.inicial = replace(numeracao, numeracao < 500, 501)) %>%
      select(PROJETO, numeracao.inicial)
  }
  
  # Juntar numeracao inicial ao resultado final
  result_points <- result_points %>%
    left_join(parcelasinv, by = "PROJETO") %>%
    mutate(numeracao.inicial = replace_na(numeracao.inicial, 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao.inicial)) %>%
    ungroup() %>%
    select(-Area, -numeracao.inicial)
  
  return(result_points)
}
