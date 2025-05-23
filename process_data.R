library(glue)
library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,    # aqui é o máximo permitido
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
    if (nrow(talhao)==0) next
    
    # número de pontos requisitados
    area_ha <- talhao$AREA_HA[1]
    n_req   <- max(2, ceiling(area_ha / intensidade_amostral))
    
    # delta ideal e limites explícitos
    delta_ideal <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta_min   <- 30
    delta_max   <- distancia_parcelas
    # se o ideal for maior que o máximo, comece no máximo
    delta       <- min(delta_ideal, delta_max)
    
    # se mesmo com delta=30 não couber, já pule
    if (delta_min * sqrt(n_req) > sqrt(as.numeric(st_area(talhao)))) {
      message(glue("Talhão {idx}: área muito pequena para {n_req} parcelas com 30 m"))
      next
    }
    
    print(glue(
      "Talhão {idx}: n_req={n_req} | delta_ideal={round(delta_ideal,1)} ",
      "| iniciar em {round(delta,1)} (min=30, max={delta_max})"
    ))
    
    max_iter  <- 100
    iter      <- 0
    best_diff <- Inf
    best_pts  <- NULL
    best_delta<- delta
    pts_sel   <- NULL
    
    while (iter < max_iter) {
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
      
      # salva melhor
      if (diff < best_diff) {
        best_diff  <- diff
        best_pts   <- pts_tmp
        best_delta <- delta
      }
      
      if (n_pts == n_req) {
        pts_sel <- pts_tmp
        break
      }
      
      # ajusta delta dentro de [delta_min, delta_max]
      if (n_pts < n_req) {
        # poucos pontos → precisa densificar → diminuir delta
        delta_novo <- max(delta * 0.95, delta_min)
      } else {
        # muitos pontos → espaçar mais → aumentar delta
        delta_novo <- min(delta * 1.05, delta_max)
      }
      
      # se não mudou, estamos num limite (min ou max)
      if (delta_novo == delta) break
      
      delta <- delta_novo
      iter  <- iter + 1
    }
    
    # Pós-processamento: só aceitamos menos pontos se estivermos num limite
    if (is.null(pts_sel)) {
      if ((delta == delta_min || delta == delta_max) && best_diff <= 1) {
        pts_sel <- best_pts
        delta   <- best_delta
        message(glue(
          "Talhão {idx}: atingiu limite delta={round(delta,1)} m; ",
          "aceitando {length(pts_sel)} pontos (±1)"))
      } else {
        message(glue(
          "Talhão {idx}: não couberam {n_req} parcelas ",
          "com 30 m ≤ delta ≤ {delta_max} m"))
        next
      }
    }
    
    # ordena e seleciona exatos n_req
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
    
    update_progress(round(i/total_poly*100,1))
  }
  
  bind_rows(result_pts) %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}
