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
      Index   = paste0(ID_PROJETO, TALHAO),
      AREA_HA = if ("AREA_HA" %in% names(.)) 
        as.numeric(AREA_HA)
      else as.numeric(st_area(.) / 10000)
    )

  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  indices    <- unique(shapeb$Index)
  total_poly <- length(indices)
  result_pts <- vector("list", total_poly)
  
  for (i in seq_along(indices)) {
    idx    <- indices[i]
    talhao <- shapeb[shapeb$Index == idx, ]
    if (nrow(talhao) == 0) next
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) next

    area_ha <- talhao$AREA_HA[1]
    n_req   <- max(2, ceiling(area_ha / intensidade_amostral))

    delta_max <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta     <- delta_max
    delta_min <- max(distancia_parcelas, 30)  
    
    print(glue(
      "Talhão: {idx} | n_req: {n_req} | delta_inicial: {round(delta,2)} m | ",
      "INT_amostral: {intensidade_amostral} | Área: {round(area_ha,2)} ha"
    ))

    max_iter  <- 100
    iter      <- 0
    best_diff <- Inf
    best_pts  <- NULL
    best_delta<- delta
    pts_sel   <- NULL

    while (iter < max_iter) {
      # cria grid de centros
      bb       <- st_bbox(talhao)
      offset_x <- runif(1, 0, delta)
      offset_y <- runif(1, 0, delta)
      offset   <- c(bb$xmin + offset_x, bb$ymin + offset_y)
      
      grid_all <- st_make_grid(
        talhao,
        cellsize = c(delta, delta),
        offset   = offset,
        what     = "centers"
      ) %>% st_cast("POINT")
      
      inside   <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      pts_tmp  <- grid_all[inside]
      n_pts    <- length(pts_tmp)
      diff     <- abs(n_pts - n_req)

      if (diff < best_diff) {
        best_diff  <- diff
        best_pts   <- pts_tmp
        best_delta <- delta
      }

      if (n_pts == n_req) {
        pts_sel <- pts_tmp
        break
      }

      if (n_pts < n_req) {
        delta_novo <- max(delta * 0.95, delta_min)
      } else {
        delta_novo <- min(delta * 1.05, delta_max)
      }

      if (delta_novo == delta) {
        message(glue(
          "Talhão {idx}: não é possível encaixar {n_req} parcelas ",
          "com distância em [{round(delta_min,1)}, {round(delta_max,1)}] m"
        ))
        break
      }
      
      delta <- delta_novo
      iter  <- iter + 1
    }

    if (is.null(pts_sel)) {
      if (best_diff <= 1) {
        pts_sel <- best_pts
        delta   <- best_delta
        message(glue(
          "Talhão {idx}: aceitando {length(pts_sel)} pontos ",
          "(margem ±1) com delta = {round(delta,1)} m"
        ))
      } else {
        message(glue(
          "Talhão {idx}: impossível alocar {n_req} parcelas ",
          "com distância ≥ {round(delta_min,1)} m"
        ))
        next
      }
    }

    cr  <- st_coordinates(pts_sel)
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

    update_progress(round(i / total_poly * 100, 1))
  }

  bind_rows(result_pts) %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}
