
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
    area_ha  <- unique(talhao$AREA_HA)
    subgeo   <- split_subgeometries(talhao)
    
    for (i in seq_len(nrow(subgeo))) {
      sg      <- subgeo[i, ]
      area_sg <- as.numeric(st_area(sg))
      if (area_sg < 400) next
      
      n_req <- ceiling(area_ha / intensidade_amostral)
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
