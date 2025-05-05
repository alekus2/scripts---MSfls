library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         intensidade_amostral,
                         update_progress) {
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = paste0(ID_PROJETO, TALHAO),
      AREA_HA = as.numeric(AREA_HA)
    )
  
  buf_dist <- -abs(distancia.minima)
  shapeb   <- shape_full %>%
    st_buffer(buf_dist) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  total_poly    <- n_distinct(shapeb$Index)
  completed     <- 0
  
  for (idx in unique(shapeb$Index)) {
    talhao   <- filter(shapeb, Index == idx)
    area_ha  <- unique(talhao$AREA_HA)  # A área agora é diretamente da coluna AREA_HA do shapefile
    subgeo   <- split_subgeometries(talhao)
    
    for (i in seq_len(nrow(subgeo))) {
      sg      <- subgeo[i, ]
      area_sg <- area_ha  # Usar a área da coluna AREA_HA
      if (area_sg < 400) next
      
      n_req <- ceiling(area_ha / intensidade_amostral)
      n_req <- min(n_req, floor(area_sg / intensidade_amostral))  # Limitar o número de pontos
      if (n_req < 1) next  # Se não houver pontos requeridos, continuar
      
      delta <- sqrt(area_sg / n_req)
      bb    <- st_bbox(sg)
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
      
      pts <- st_sfc()
      for (iter in seq_len(20)) {
        grid_pts <- st_make_grid(
          x        = sg,
          cellsize = c(delta, delta),
          offset   = offset_xy,
          what     = "centers"
        )
        inside <- st_within(grid_pts, sg, sparse = FALSE)
        cand   <- grid_pts[apply(inside, 1, any)]
        if (length(cand) >= n_req) {
          cand <- cand[1:n_req * 2]  
          break
        }
        delta <- delta * 0.95
      }
      if (length(cand) == 0) next
      
      # enforce minimum spacing = delta * 0.8
      min_dist <- delta * 0.8
      sel <- vector("list", 0)
      for (pt in cand) {
        if (length(sel) == 0) {
          sel <- list(pt)
        } else {
          dists <- sapply(sel, function(x) as.numeric(st_distance(x, pt)))
          if (all(dists >= min_dist)) sel <- append(sel, list(pt))
        }
        if (length(sel) == n_req) break
      }
      if (length(sel) == 0) next
      sel <- st_sfc(sel, crs = st_crs(sg))
      coords  <- st_coordinates(sel)
      n_found <- nrow(coords)
      pts_sf  <- st_sf(
        data.frame(
          Index      = rep(idx, n_found),
          PROJETO    = rep(talhao$ID_PROJETO, n_found),
          TALHAO     = rep(talhao$TALHAO, n_found),
          CICLO      = rep(talhao$CICLO, n_found),
          ROTACAO    = rep(talhao$ROTACAO, n_found),
          STATUS     = rep("ATIVA", n_found),
          FORMA      = rep(forma_parcela, n_found),
          TIPO_INSTA = rep(tipo_parcela, n_found),
          TIPO_ATUAL = rep(tipo_parcela, n_found),
          DATA       = rep(Sys.Date(), n_found),
          DATA_ATUAL = rep(Sys.Date(), n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel
      )
      
      result_points[[paste(idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  all_pts <- do.call(rbind, result_points)
  
  all_pts <- all_pts %>%
    group_by(Index) %>%
    mutate(PARCELAS = row_number()) %>%
    ungroup()
  
  all_pts
}
                          
Listening on http://127.0.0.1:6158
Reading layer `parc' from data source 
  `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' 
  using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
Aviso em st_cast.sf(shape[i, ], "POLYGON") :
  repeating attributes for all sub-geometries for which they may not be constant
Aviso: Error in UseMethod: método não aplicável para 'group_by' aplicado a um objeto de classe "NULL"
  86: group_by
  85: mutate
  84: ungroup
  83: %>%
  82: process_data [src/process_data.R#108]
  81: observe [src/server.R#82]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp

                                        
