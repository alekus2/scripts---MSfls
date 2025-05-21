library(glue)
library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,
                         intensidade_amostral,
                         update_progress) {
  
  parc_exist <- suppressMessages(st_read(parc_exist_path)) %>% 
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index = paste0(ID_PROJETO, TALHAO),
      AREA_HA = if ("AREA_HA" %in% names(.)) 
        as.numeric(AREA_HA)
      else as.numeric(st_area(.) / 10000)
    )
  
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  indices <- unique(shapeb$Index)
  total_poly <- length(indices)
  result_pts <- vector("list", total_poly)
  
  for (i in seq_along(indices)) {
    idx <- indices[i]
    talhao <- shapeb[shapeb$Index == idx, ]
    if (nrow(talhao) == 0) next
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) next
    index <- talhao$Index
    area_ha <- talhao$AREA_HA[1]
    n_req <- max(2, ceiling(area_ha / intensidade_amostral))
    delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta_step <- 1
    
    print(glue("Talhão: {index} | Número de parcelas recomendadas: {n_req} | Numero sequencial da parcela: {pts_all} | Valor da distancia entre as parcelas do talhao atual(equivale para todos os pontos: | Intensidade amostral: {intensidade_amostral} | Área do talhão: {area_ha}"))
    
    max_iter <- 50
    iter <- 0
    pts_sel <- NULL
    
    while (iter < max_iter) {
      bb <- st_bbox(talhao)
      offset <- c(bb$xmin + delta / 2, bb$ymin + delta / 2)
      
      grid_all <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset, what = "centers")
      grid_all <- st_cast(grid_all, "POINT")
      inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      pts_tmp <- grid_all[inside_poly]
      
      if (length(pts_tmp) == n_req) {
        pts_sel <- pts_tmp
        break
      } else if (length(pts_tmp) < n_req) {
        delta <- delta * 0.9
      } else {
        delta <- delta * 1.1
      }
      
      iter <- iter + 1
    }
    
    if (is.null(pts_sel) || length(pts_sel) != n_req) {
      next
    }
    
    cr <- st_coordinates(pts_sel)
    ord <- order(cr[,1], cr[,2])
    sel <- pts_sel[ord][seq_len(n_req)]
    
    df <- tibble(
      Index      = idx,
      PROJETO    = talhao$ID_PROJETO[1],
      TALHAO     = talhao$TALHAO[1],
      CICLO      = talhao$CICLO[1],
      ROTACAO    = talhao$ROTACAO[1],
      STATUS     = "ATIVA",
      FORMA      = forma_parcela,
      TIPO_INSTA = tipo_parcela,
      TIPO_ATUAL = tipo_parcela,
      DATA       = Sys.Date(),
      DATA_ATUAL = Sys.Date(),
      COORD_X    = st_coordinates(sel)[,1],
      COORD_Y    = st_coordinates(sel)[,2],
      AREA_HA    = area_ha
    )
    
    pts_sf <- st_sf(df, geometry = sel, crs = st_crs(shape_full))
    result_pts[[i]] <- pts_sf
    update_progress(round(i/total_poly * 100, 1))
  }
  
  all_pts <- bind_rows(result_pts)
  
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}
