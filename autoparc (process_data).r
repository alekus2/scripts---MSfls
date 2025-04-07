process_data <- function(shape, recomend, parc_exist_path, forma_parcela, tipo_parcela, distancia.minima, grid_existente, update_progress) {
  
  parc_exist <- st_read(parc_exist_path)
  
  shape <- st_transform(shape, 31982)
  parc_exist <- st_transform(parc_exist, 31982)
  
  shape$Index <- paste0(shape$ID_PROJETO, shape$ID_TALHAO)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)
  
  buffer_distance <- -15
  
  shapeb <- list()
  empty_indexes <- c()
  
  for (i in 1:nrow(shape)) {
    if (st_is_empty(st_buffer(shape[i,], buffer_distance))) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      dt_aux <- st_buffer(shape[i,], buffer_distance)
      shapeb[[i]] <- dt_aux
    }
  }
  
  if(!is.null(empty_indexes)) {
    shapeb <- shapeb[-empty_indexes]
  }
  shapeb <- do.call("rbind", shapeb)
  
  result_points <- list()
  points2 <- NULL
  aux <- 1
  tempo <- 0
  
  total_poly_idx <- length(unique(shapeb$Index)) 
  completed_poly_idx <- 0
  
  for (poly_idx in unique(shapeb$Index)) { 
    poly <- shapeb[shapeb$Index == poly_idx,]
    subgeoms <- split_subgeometries(poly)
    
    for (i in 1:nrow(subgeoms)) {
      if(as.numeric(st_area(subgeoms[i,])) < 400) {
        next
      } else {
        sg <- subgeoms[i,]
        sg_area <- as.numeric(st_area(sg))
        active_points_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx,]
        active_points <- st_intersection(st_geometry(active_points_all), st_geometry(sg))
        
        if (sg_area >= 400 & sg_area <= 1000) {
          if (length(active_points) > 0) {
            next
          } else {
            cell.point <- st_centroid(st_geometry(sg))
            
            conf.point <- st_buffer(cell.point, dist = sqrt(400 / pi))
            conf.point <- st_intersection(conf.point, sg) %>% st_sf()
            
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
          num_parc <- recomend[recomend$Index == poly_idx, "Num.parc"]
          
          # Use the existing grid instead of creating a new one
          grid <- grid_existente[grid_existente$Index == poly_idx,] # Filtre o grid existente para o polígono atual
          
          grid <- st_intersection(grid, sg) %>% st_sf() # Interseccione com a subgeometria
          
          if(nrow(grid) == 0) {
            next
          }
          
          if(num_parc > nrow(grid)) {
            num_parc <- nrow(grid)
          }
          
          indices_grid <- sample(nrow(grid), num_parc) # Se quiser manter a aleatoriedade, mantenha esta linha
          grid_selecionado <- grid[indices_grid,]
          
          points_list <- list()
          for (j in 1:nrow(grid_selecionado)) {
            cell <- grid_selecionado[j,]
            active_points_cell <- st_intersection(st_geometry(active_points), st_geometry(cell))
            
            if (length(active_points_cell) == 0) {
              cell.point <- st_centroid(st_geometry(cell))
              
              area_vector <- as.numeric(st_area(cell))
              index_vector <- rep(poly_idx, length(area_vector))
              
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
        
        result_points[[paste(poly_idx, i, sep = "-" )]] <- points2
      }
    }
    
    completed_poly_idx <- completed_poly_idx + 1
    progress_percent <- round((completed_poly_idx / total_poly_idx) * 100, 2)
    update_progress(progress_percent)
  }
  
  result_points <- do.call("rbind", result_points)
  
  # Continue com o restante do código...
  
  return(result_points)
}