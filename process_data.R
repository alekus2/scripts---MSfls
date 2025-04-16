process_data <- function(shape, recomend, parc_exist_path, forma_parcela, 
                         tipo_parcela, distancia.minima, intensidade_amostral, 
                         update_progress) {
  
  library(sf)
  library(dplyr)
  library(tidyr)
  
  parc_exist <- st_read(parc_exist_path)
  shape <- st_transform(shape, 31982)
  parc_exist <- st_transform(parc_exist, 31982)
  
  shape$Index <- paste0(shape$ID_PROJETO, shape$ID_TALHAO)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)
  
  buffer_distance <- -15
  shapeb <- list()
  empty_indexes <- c()
  
  for (i in 1:nrow(shape)) {
    buffered <- st_buffer(shape[i, ], buffer_distance)
    if (st_is_empty(buffered)) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      shapeb[[i]] <- buffered
    }
  }
  if (!is.null(empty_indexes) && length(empty_indexes) > 0) {
    shapeb <- shapeb[-empty_indexes]
  }
  shapeb <- do.call("rbind", shapeb)
  
  result_points <- list()
  completed_poly_idx <- 0
  total_poly_idx <- length(unique(shapeb$Index))
  
  for (poly_idx in unique(shapeb$Index)) {
    
    poly <- shapeb[shapeb$Index == poly_idx, ]
    subgeoms <- split_subgeometries(poly)
    
    for (i in 1:nrow(subgeoms)) {
      sg <- subgeoms[i, ]
      sg_area <- as.numeric(st_area(sg))
      
      if (sg_area < 400) next
      
      active_points_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx, ]
      active_points <- st_intersection(st_geometry(active_points_all), st_geometry(sg))
      
      if (sg_area >= 400 & sg_area <= 1000) {
        if (length(active_points) > 0) next
        
        cell.point <- st_centroid(st_geometry(sg))
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
        
      } else {
        num_parc_recom <- as.numeric(recomend[recomend$Index == poly_idx, "Num.parc"])
        num_parc_desejado <- round(num_parc_recom * as.numeric(intensidade_amostral))
        
        sg_area_ha <- sg_area / 10000
        max_possible_plots <- floor(sg_area_ha / as.numeric(intensidade_amostral))
        num_parc <- min(num_parc_desejado, max_possible_plots)
        
        if (num_parc == 0) next
        
        # Definir número de linhas e colunas para a malha sistemática
        num_cols <- ceiling(sqrt(num_parc))
        num_rows <- ceiling(num_parc / num_cols)
        
        bbox <- st_bbox(sg)
        cell_width <- (bbox$xmax - bbox$xmin) / num_cols
        cell_height <- (bbox$ymax - bbox$ymin) / num_rows
        
        grid <- st_make_grid(sg, cellsize = c(cell_width, cell_height), what = "polygons", square = TRUE)
        grid <- st_intersection(grid, sg) %>% st_sf()
        grid$area.grid <- round(as.numeric(st_area(grid)))
        grid <- grid %>% filter(area.grid >= (cell_width * cell_height * 0.7))
        
        if(nrow(grid) == 0) next
        
        grid_selecionado <- head(grid, num_parc)
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
          }
        }
        if (length(points_list) > 0) {
          points2 <- do.call("rbind", points_list)
          result_points[[paste(poly_idx, i, sep = "-")]] <- points2
        }
      }
      completed_poly_idx <- completed_poly_idx + 1
    }
    progress_percent <- round((completed_poly_idx / total_poly_idx) * 100, 2)
    update_progress(progress_percent)
  }
  
  result_points <- do.call("rbind", result_points)
  
  parcelasinv <- parc_exist %>%
    dplyr::group_by(PROJETO) %>%
    dplyr::summarise(numeracao = max(PARCELAS[PARCELAS < 500]),
                     numeracao2 = max(PARCELAS)) %>% as.data.frame()
  
  if (tipo_parcela %in% c("IFQ6", "IFQ12", "S30", "S90", "PP")) {
    parcelasinv <- parcelasinv %>%
      dplyr::mutate(numeracao.inicial = if_else(numeracao == 499, numeracao2 + 1, numeracao + 1)) %>%
      dplyr::select(PROJETO, numeracao.inicial)
  } else {
    parcelasinv <- parcelasinv %>%
      dplyr::mutate(numeracao.inicial = dplyr::if_else(numeracao < 500, 501, numeracao)) %>%
      dplyr::select(PROJETO, numeracao.inicial)
  }
  
  result_points <- result_points %>%
    dplyr::left_join(parcelasinv, by = "PROJETO") %>%
    dplyr::mutate(numeracao.inicial = tidyr::replace_na(numeracao.inicial, 1)) %>%
    dplyr::group_by(PROJETO) %>%
    dplyr::mutate(PARCELAS = dplyr::row_number() - 1 + dplyr::first(numeracao.inicial)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-Area, -numeracao.inicial)
  
  return(result_points)
}
