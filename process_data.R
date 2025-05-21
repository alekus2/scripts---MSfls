process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas_init,
                         intensidade_amostral,  
                         update_progress) {
  
  # 1. Leitura e projeção
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
  
  # 2. Buffer interno
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  indices    <- unique(shapeb$Index)
  total_poly <- length(indices)
  result_pts <- vector("list", total_poly)
  
  for (i in seq_along(indices)) {
    idx     <- indices[i]
    talhao  <- shapeb[shapeb$Index == idx, ]
    if (nrow(talhao) == 0) next
    
    # confirma geometria válida
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) next
    
    area_ha <- talhao$AREA_HA[1]
    # número de pontos desejados
    n_req   <- max(1, ceiling(area_ha / intensidade_amostral))
    
    # inicia delta a partir do valor inicial
    delta    <- distancia_parcelas_init
    min_delta <- 1    # limite inferior do passo
    pts_sel <- NULL
    
    # obtém bbox numérico
    bb <- st_bbox(talhao)
    if (any(is.infinite(bb)) || any(is.na(bb))) next
    
    # laço decrescente sobre delta  
    while (delta >= min_delta) {
      # gera grid sobre o bbox, depois filtra dentro da geometria
      grid_all <- st_make_grid(
        x        = st_as_sfc(bb), 
        cellsize = c(delta, delta),
        what     = "centers"
      )
      if (length(grid_all) == 0) {
        delta <- delta - 1
        next
      }
      # garante que é sfc_POINT
      grid_all <- st_cast(grid_all, "POINT")
      
      # mantém só pontos dentro do polígono (ou círculo + polígono)
      if (forma_parcela == "circular") {
        centro <- st_centroid(talhao)
        raio   <- sqrt(area_ha * 10000 / pi)
        coords <- st_coordinates(grid_all)
        c0     <- st_coordinates(centro)
        d2     <- (coords[,1] - c0[1])^2 + (coords[,2] - c0[2])^2
        inside_circle <- d2 <= raio^2
        inside_poly   <- st_within(grid_all, talhao, sparse = FALSE)[,1]
        keep_idx <- which(inside_circle & inside_poly)
      } else {
        inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
        keep_idx <- which(inside_poly)
      }
      pts_tmp <- grid_all[keep_idx]
      
      if (length(pts_tmp) >= n_req) {
        pts_sel <- pts_tmp
        break
      }
      delta <- delta - 1
    }
    
    # fallback: 1 ponto no centróide se nada coube
    if (is.null(pts_sel) || length(pts_sel) < n_req) {
      base_pt <- st_centroid(st_geometry(talhao)[[1]])
      pts_sel <- st_sfc(rep(base_pt, n_req), crs = st_crs(shape_full))
    }
    
    # ordena por X, depois Y, e seleciona os primeiros n_req
    cr   <- st_coordinates(pts_sel)
    ord  <- order(cr[,1], cr[,2])
    sel  <- pts_sel[ord][seq_len(n_req)]
    
    # monta o sf resultante
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
  
  # concatena tudo
  all_pts <- bind_rows(result_pts)
  if (nrow(all_pts) == 0) {
    stop("Nenhum ponto gerado após o processamento dos talhões.")
  }
  
  # garante pelo menos 2 pontos por talhão
  counts <- all_pts %>% st_drop_geometry() %>% count(Index, name = "n_pts")
  to_fix <- counts %>% filter(n_pts < 2)
  
  if (nrow(to_fix) > 0) {
    extras <- map2_df(
      to_fix$Index, to_fix$n_pts,
      function(idx, n_pts) {
        need   <- 2 - n_pts
        shape_row <- filter(shape_full, Index == idx)
        base_pt <- st_centroid(st_geometry(shape_row)[[1]])
        df0 <- tibble(
          Index      = idx,
          PROJETO    = shape_row$ID_PROJETO[1],
          TALHAO     = shape_row$TALHAO[1],
          CICLO      = shape_row$CICLO[1],
          ROTACAO    = shape_row$ROTACAO[1],
          STATUS     = "ATIVA",
          FORMA      = forma_parcela,
          TIPO_INSTA = tipo_parcela,
          TIPO_ATUAL = tipo_parcela,
          DATA       = Sys.Date(),
          DATA_ATUAL = Sys.Date(),
          COORD_X    = st_coordinates(base_pt)[1],
          COORD_Y    = st_coordinates(base_pt)[2],
          AREA_HA    = shape_row$AREA_HA[1]
        )
        geom <- st_sfc(rep(base_pt, need), crs = st_crs(shape_full))
        st_sf(df0[rep(1, need), ], geometry = geom)
      }
    )
    all_pts <- bind_rows(all_pts, extras)
  }
  
  # numera as parcelas
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}


Listening on http://127.0.0.1:4799
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
Aviso: Error in map2_df: não foi possível encontrar a função "map2_df"
  82: process_data [src/process_data.R#119]
  81: observe [src/server.R#74]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp
