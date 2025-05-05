for (idx in unique(shapeb$Index)) {
  talhao   <- filter(shapeb, Index == idx)  
  area_ha  <- as.numeric(unique(talhao$AREA_HA))
  
  # número exato de pontos que queremos no talhão inteiro
  n_req <- max(1, floor(area_ha / intensidade_amostral))
  
  # dá pra pular talhões muito pequenos, se quiser
  if (area_ha < 0.004) next
  
  # spacing inicial aproximado para um grid quadrado
  delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
  
  # centraliza o grid dentro do bbox
  bb <- st_bbox(talhao)
  offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
  
  pts <- NULL
  for (iter in seq_len(20)) {
    grid_pts <- st_make_grid(
      x        = talhao,
      cellsize = c(delta, delta),
      offset   = offset_xy,
      what     = "centers"
    )
    inside   <- st_within(grid_pts, talhao, sparse = FALSE)
    pts_all  <- grid_pts[apply(inside, 1, any)]
    
    if (length(pts_all) >= n_req) {
      # se temos pontos suficientes, pare de diminuir spacing
      pts <- pts_all
      break
    }
    # senão diminui um pouco o delta e tenta de novo
    delta <- delta * 0.95
  }
  
  # se mesmo assim não coube, pula esse talhão
  if (is.null(pts) || length(pts) < n_req) {
    message(glue::glue("Talhão {idx} só comporta {length(pts)} pontos ( precisava de {n_req} ). Pulando."))
    next
  }
  
  # agora seleciona só n_req pontos (ordenados pra manter padronização)
  cr   <- st_coordinates(pts)
  ord  <- order(cr[,1], cr[,2])
  sel  <- pts[ord][1:n_req]
  
  # constrói o sf como você já faz
  coords   <- st_coordinates(sel)
  pts_sf   <- st_sf(
    data.frame(
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
      COORD_X    = coords[,1],
      COORD_Y    = coords[,2]
    ),
    geometry = sel
  )
  
  result_points[[idx]] <- pts_sf
  update_progress(round( which(unique(shapeb$Index)==idx) / total_poly * 100, 2))
}
