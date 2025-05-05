library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,      
                         intensidade_amostral,  
                         update_progress) {    
  
  
  
  
  parc_exist <- st_read(parc_exist_path) %>% 
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = as.character(CD_USO_SOL),
      AREA_HA = as.numeric(AREA_HA)
    )
  
  buf_dist <- -abs(distancia.minima)
  shapeb   <- shape_full %>%
    st_buffer(buf_dist) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  total_poly   <- n_distinct(shapeb$Index)
  completed    <- 0
  
  for (idx in unique(shapeb$Index)) {
    talhao   <- filter(shapeb, Index == idx)
    area_ha  <- unique(talhao$AREA_HA)    
    subgeo   <- split_subgeometries(talhao)
    
    for (i in seq_len(nrow(subgeo))) {
      sg      <- subgeo[i, ]
      area_sg <- as.numeric(st_area(sg))   
      if (area_sg < 400) next              
      
      n_req <- max(1, floor(area_ha / intensidade_amostral))
      
      delta     <- sqrt(area_sg / n_req)
      bb        <- st_bbox(sg)
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
      
      for (iter in seq_len(20)) {
        grid_pts <- st_make_grid(
          x        = sg,
          cellsize = c(delta, delta),
          offset   = offset_xy,
          what     = "centers"
        )
        inside   <- st_within(grid_pts, sg, sparse = FALSE)
        pts      <- grid_pts[apply(inside, 1, any)]
        
        if (length(pts) >= n_req) break
        delta <- delta * 0.95  
        
      }
      
      if (length(pts) == 0) next
      
      cr      <- st_coordinates(pts)
      ord     <- order(cr[,1], cr[,2])
      sel_pts <- pts[ord][ seq_len(min(length(pts), n_req)) ]
      
      coords   <- st_coordinates(sel_pts)
      n_found  <- nrow(coords)
      pts_sf   <- st_sf(
        data.frame(
          Index      = rep(idx,      n_found),
          PROJETO    = rep(talhao$ID_PROJETO, n_found),
          TALHAO     = rep(talhao$TALHAO,    n_found),
          CICLO      = rep(talhao$CICLO,     n_found),
          ROTACAO    = rep(talhao$ROTACAO,   n_found),
          STATUS     = rep("ATIVA",          n_found),
          FORMA      = rep(forma_parcela,    n_found),
          TIPO_INSTA = rep(tipo_parcela,     n_found),
          TIPO_ATUAL = rep(tipo_parcela,     n_found),
          DATA       = rep(Sys.Date(),       n_found),
          DATA_ATUAL = rep(Sys.Date(),       n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel_pts
      )
      
      result_points[[paste(idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  all_pts <- do.call(rbind, result_points)
  
  parcelasinv <- parc_exist %>%
    st_drop_geometry() %>%
    group_by(PROJETO) %>%
    summarise(
      max_antiga = max(PARCELAS[PARCELAS < 500], na.rm = TRUE),
      max_geral  = max(PARCELAS, na.rm = TRUE)
    ) %>%
    mutate(
      numeracao_inicial = if_else(
        tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP"),
        if_else(max_antiga == 499, max_geral + 1, max_antiga + 1),
        if_else(max_antiga < 500, 501, max_antiga + 1)
      )
    ) %>%
    select(PROJETO, numeracao_inicial)
  
  all_pts <- all_pts %>%
    left_join(parcelasinv, by = "PROJETO") %>%
    replace_na(list(numeracao_inicial = 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao_inicial)) %>%
    ungroup() %>%
    select(-numeracao_inicial)
  
  return(all_pts)
}

Listening on http://127.0.0.1:6158
Aviso: Error in : Cannot open "CIRCULAR"; The file doesn't seem to exist.
  89: <Anonymous>
  88: stop
  84: st_transform
  82: process_data [src/process_data.R#13]
  81: observe [src/server.R#82]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp
