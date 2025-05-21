process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,
                         intensidade_amostral,  
                         update_progress) {
  
  parc_exist <- suppressMessages(st_read(parc_exist_path)) %>% st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = paste0(ID_PROJETO, TALHAO),
      AREA_HA = if ("AREA_HA" %in% names(.)) as.numeric(AREA_HA) else as.numeric(st_area(.) / 10000)
    )
  
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  result_points <- list()
  indices      <- unique(shapeb$Index)
  total_poly   <- length(indices)
  
  for (i in seq_along(indices)) {
    idx    <- indices[i]
    talhao <- filter(shapeb, Index == idx)
    if (nrow(talhao) == 0) next
    
    # Confirma que talhão tem geometria válida e não vazia
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) {
      message(glue("Talhão {idx} vazio ou inválido após buffer, pulando..."))
      next
    }
    
    area_ha <- unique(talhao$AREA_HA)
    n_req   <- max(1, ceiling(area_ha / intensidade_amostral))
    
    delta <- distancia_parcelas
    bb <- st_bbox(talhao)
    
    # Se bbox inválido (por ex. zeros ou Inf) pula talhão
    if (any(is.infinite(bb)) || any(is.na(bb))) {
      message(glue("BBox inválido para talhão {idx}, pulando..."))
      next
    }
    
    if (forma_parcela == "circular") {
      centro <- st_centroid(talhao)
      raio <- sqrt(area_ha * 10000 / pi)
    }
    
    pts_all <- NULL
    min_delta <- 10
    
    while (delta >= min_delta) {
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
      
      grid_pts <- st_make_grid(
        x        = talhao,
        cellsize = c(delta, delta),
        offset   = offset_xy,
        what     = "centers"
      )
      
      # Proteção se grade vazia
      if (length(grid_pts) == 0) {
        delta <- delta - 1
        next
      }
      
      # Verifica se todos elementos são geometria sfg
      if (!all(sapply(grid_pts, function(g) inherits(g, "sfg")))) {
        message(glue("Grade com geometria inválida no talhão {idx}, pulando iteração."))
        delta <- delta - 1
        next
      }
      
      if (forma_parcela == "quadrada") {
        inside <- st_within(grid_pts, talhao, sparse = FALSE)
        pts_tmp <- grid_pts[which(rowSums(inside) > 0)]
      } else if (forma_parcela == "circular") {
        inside_poly <- st_within(grid_pts, talhao, sparse = FALSE)
        coords_pts <- st_coordinates(grid_pts)
        coords_centro <- st_coordinates(centro)
        dist_centro <- sqrt((coords_pts[,1] - coords_centro[1])^2 + (coords_pts[,2] - coords_centro[2])^2)
        inside_circle <- dist_centro <= raio
        pts_tmp <- grid_pts[which(rowSums(inside_poly) > 0 & inside_circle)]
      } else {
        inside <- st_within(grid_pts, talhao, sparse = FALSE)
        pts_tmp <- grid_pts[which(rowSums(inside) > 0)]
      }
      
      if (length(pts_tmp) >= n_req) {
        pts_all <- pts_tmp
        break
      }
      
      delta <- delta - 1
    }
    
    if (is.null(pts_all) || length(pts_all) < n_req) {
      fallback_geom <- st_geometry(talhao)[[1]]
      if (is.null(fallback_geom)) {
        message(glue("Fallback falhou para talhão {idx} - geometria nula"))
        next
      }
      pts_all <- st_centroid(fallback_geom)
      while (length(pts_all) < n_req) {
        pts_all <- c(pts_all, pts_all[1])
      }
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
        AREA_HA    = rep(area_ha,             n_req)
      ),
      geometry = sel,
      crs = st_crs(shape_full)
    )
    
    result_points[[idx]] <- pts_sf
    update_progress(round(i/total_poly*100, 1))
  }
  
  all_pts <- do.call(rbind, result_points)
  
  # Correção: checar se all_pts não está vazio antes de operar
  if (nrow(all_pts) == 0) {
    stop("Nenhum ponto gerado após o processamento dos talhões.")
  }
  
  counts <- all_pts %>% st_drop_geometry() %>% count(Index, name = "n_pts")
  to_fix <- filter(counts, n_pts < 2)
  
  if (nrow(to_fix) > 0) {
    extras <- lapply(seq_len(nrow(to_fix)), function(i) {
      idx <- to_fix$Index[i]
      shape_row <- filter(shape_full, Index == idx)
      if (nrow(shape_row) == 0) return(NULL)
      
      base_geom <- st_geometry(shape_row)
      if (length(base_geom) == 0 || is.null(base_geom[[1]])) return(NULL)
      
      base_pt <- st_centroid(base_geom[[1]])
      need <- 2 - to_fix$n_pts[i]
      area_ha <- shape_row$AREA_HA[1]
      
      df0 <- data.frame(
        Index      = rep(idx, need),
        PROJETO    = rep(shape_row$ID_PROJETO[1], need),
        TALHAO     = rep(shape_row$TALHAO[1],    need),
        CICLO      = rep(shape_row$CICLO[1],     need),
        ROTACAO    = rep(shape_row$ROTACAO[1],   need),
        STATUS     = rep("ATIVA",           need),
        FORMA      = rep(forma_parcela,     need),
        TIPO_INSTA = rep(tipo_parcela,      need),
        TIPO_ATUAL = rep(tipo_parcela,      need),
        DATA       = rep(Sys.Date(),        need),
        DATA_ATUAL = rep(Sys.Date(),        need),
        COORD_X    = rep(st_coordinates(base_pt)[1], need),
        COORD_Y    = rep(st_coordinates(base_pt)[2], need),
        AREA_HA    = rep(area_ha,           need)
      )
      st_sf(df0, geometry = st_sfc(rep(base_pt, need), crs = st_crs(shape_full)))
    })
    all_pts <- bind_rows(all_pts, do.call(rbind, extras[!sapply(extras, is.null)]))
  }
  
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}

quero que meu codigo calcule o grid com base na distancia entre os pontos. Onde o codigo deverá usar toda area do talhão e usando o buffer tambem para não criar pontos nas bordas e conforme for criando os pontos ir diminuindo de 1 em 1 até couber todos os pontos recomendados q será com base na area(ha) / pela intensidade amostral
mas meu codigo apresenta esse erro abaixo:
                      
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em min(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em min(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso: Error in : object(s) should be of class 'sfg'
  89: <Anonymous>
  88: stop
  87: sfc_unique_sfg_dims_and_types
  86: st_sfc
  84: FUN [src/process_data.R#174]
  83: lapply
  82: process_data [src/process_data.R#146]
  81: observe [src/server.R#74]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp

então quero que voce ache uma maneira de meu app funcionar corretamente. Pois essa é apenas uma parte dele.
