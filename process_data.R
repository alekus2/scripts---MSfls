
library(sf)
library(dplyr)
library(glue)


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
    idx     <- indices[i]
    talhao  <- filter(shapeb, Index == idx)
    area_ha <- unique(talhao$AREA_HA)
    n_req   <- max(1, ceiling(area_ha / intensidade_amostral))
    delta   <- distancia_parcelas
    bb      <- st_bbox(talhao)
    offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
    
    pts_all <- NULL
    while (delta >= 50) {
      grid_pts <- st_make_grid(
        x        = talhao,
        cellsize = c(delta, delta),
        offset   = offset_xy,
        what     = "centers"
      )
      if (length(grid_pts) > 0) {
        inside  <- st_within(grid_pts, talhao, sparse = FALSE)
        pts_tmp <- grid_pts[which(rowSums(inside) > 0)]
        if (length(pts_tmp) >= n_req) {
          pts_all <- pts_tmp
          break
        }
      }
      delta     <- delta - 1
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
    }
    
    if (is.null(pts_all) || length(pts_all) < n_req) {
      pts_all <- if (!is.null(pts_all) && length(pts_all) > 0) pts_all else st_centroid(talhao)
      while (length(pts_all) < n_req) pts_all <- c(pts_all, pts_all[1])
    }
    
    cr  <- st_coordinates(pts_all)
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
      idx  <- to_fix$Index[i]
      need <- 2 - to_fix$n_pts[i]
      base_geom <- st_geometry(filter(shape_full, Index == idx))[[1]]
      base_pt   <- st_centroid(base_geom)
      area_ha   <- unique(filter(shape_full, Index == idx)$AREA_HA)
      df0 <- data.frame(
        Index      = rep(idx, need),
        PROJETO    = rep(shape_full$ID_PROJETO[1], need),
        TALHAO     = rep(shape_full$TALHAO[1],    need),
        CICLO      = rep(shape_full$CICLO[1],     need),
        ROTACAO    = rep(shape_full$ROTACAO[1],   need),
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
    all_pts <- bind_rows(all_pts, do.call(rbind, extras))
  }
  
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}

Listening on http://127.0.0.1:7134
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
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
Aviso em min(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso: st_centroid assumes attributes are constant over geometries
Aviso: Error in st_sf: no simple features geometry column present
  84: stop
  83: st_sf
  82: process_data [src/process_data.R#70]
  81: observe [src/server.R#74]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp
