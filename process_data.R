library(sf)
library(dplyr)
library(glue)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,      
                         intensidade_amostral,  
                         update_progress) {
  
  parc_exist <- st_read(parc_exist_path) %>% st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO),
           AREA_HA = as.numeric(AREA_HA))
  
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  indices <- unique(shapeb$Index)
  total_poly <- length(indices)
  
  for (i in seq_along(indices)) {
    idx <- indices[i]
    talhao <- filter(shapeb, Index == idx)
    area_ha <- unique(talhao$AREA_HA)
    n_req <- max(1, ceiling(area_ha / intensidade_amostral))
    delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
    bb <- st_bbox(talhao)
    offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
    
    pts_all <- NULL
    for (iter in seq_len(30)) {
      grid_pts <- st_make_grid(x = talhao, cellsize = c(delta, delta), offset = offset_xy, what = "centers")
      inside <- st_within(grid_pts, talhao, sparse = FALSE)
      pts_tmp <- grid_pts[apply(inside, 1, any)]
      if (length(pts_tmp) < n_req) {
        delta <- delta * 0.9
        next
      }
      pts_all <- pts_tmp
      break
    }
    
    if (is.null(pts_all) || length(pts_all) < n_req) {
      pts_all <- if (!is.null(pts_all) && length(pts_all) > 0) pts_all else st_centroid(talhao)
      if (length(pts_all) == 0) pts_all <- st_centroid(talhao)
      while (length(pts_all) < n_req) pts_all <- c(pts_all, pts_all[1])
    }
    
    cr <- st_coordinates(pts_all)
    ord <- order(cr[,1], cr[,2])
    sel <- pts_all[ord][1:n_req]
    
    coords <- st_coordinates(sel)
    pts_sf <- st_sf(
      data.frame(
        Index      = rep(idx, n_req),
        PROJETO    = rep(talhao$ID_PROJETO[1], n_req),
        TALHAO     = rep(talhao$TALHAO[1],    n_req),
        CICLO      = rep(talhao$CICLO[1],     n_req),
        ROTACAO    = rep(talhao$ROTACAO[1],   n_req),
        STATUS     = rep("ATIVA",             n_req),
        FORMA      = rep(forma_parcela,       n_req),
        TIPO_INSTA = rep(tipo_parcela,        n_req),
        TIPO_ATUAL = rep(tipo_parcela,        n_req),
        DATA       = rep(Sys.Date(),          n_req),
        DATA_ATUAL = rep(Sys.Date(),          n_req),
        COORD_X    = coords[,1],
        COORD_Y    = coords[,2],
        AREA_HA    = rep(area_ha, n_req)  # Adicionando a coluna AREA_HA
      ),
      geometry = sel
    )
    
    result_points[[idx]] <- pts_sf
    update_progress(round(i/total_poly*100, 1))
  }
  
  all_pts <- do.call(rbind, result_points)
  
  counts <- all_pts %>% st_drop_geometry() %>% count(Index, name = "n_pts")
  to_fix <- filter(counts, n_pts < 2)
  if (nrow(to_fix) > 0) {
    extras <- lapply(seq_len(nrow(to_fix)), function(i) {
      idx <- to_fix$Index[i]
      need <- 2 - to_fix$n_pts[i]
      base_pt <- st_centroid(filter(shape_full, Index == idx))
      df0 <- data.frame(
        Index      = rep(idx, need),
        PROJETO    = rep(base_pt$ID_PROJETO, need),
        TALHAO     = rep(base_pt$TALHAO,    need),
        CICLO      = rep(base_pt$CICLO,     need),
        ROTACAO    = rep(base_pt$ROTACAO,   need),
        STATUS     = rep("ATIVA",           need),
        FORMA      = rep(forma_parcela,     need),
        TIPO_INSTA = rep(tipo_parcela,      need),
        TIPO_ATUAL = rep(tipo_parcela,      need),
        DATA       = rep(Sys.Date(),        need),
        DATA_ATUAL = rep(Sys.Date(),        need),
        COORD_X    = rep(st_coordinates(base_pt)[1], need),
        COORD_Y    = rep(st_coordinates(base_pt)[2], need),
        AREA_HA    = rep(st_area(base_pt), need)  # Adicionando a coluna AREA_HA
      )
      st_sf(df0, geometry = st_geometry(base_pt)[rep(1, need)])
    })
    all_pts <- bind_rows(all_pts, do.call(rbind, extras))
  }
  
  all_pts <- all_pts %>%
    group_by(Index) %>%
    mutate(NM_PARCELAS = row_number()) %>%  # Alterando o nome da coluna para NM_PARCELAS
    ungroup()
  
  all_pts
}