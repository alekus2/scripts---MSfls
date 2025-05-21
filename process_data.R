library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas_init,
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
    delta <- distancia_parcelas_init
    max_delta <- 500
    pts_sel <- NULL
    bb <- st_bbox(talhao)
    if (any(is.infinite(bb)) || any(is.na(bb))) next
    repeat {
      grid_all <- st_make_grid(x = st_as_sfc(bb), cellsize = c(delta, delta), what = "centers")
      if (length(grid_all) == 0) {
        delta <- delta + 1
        if (delta > max_delta) break
        next
      }
      grid_all <- st_cast(grid_all, "POINT")
      inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      keep_idx <- which(inside_poly)
      pts_tmp <- grid_all[keep_idx]
      if (length(pts_tmp) == n_req) {
        pts_sel <- pts_tmp
        break
      }
      if (length(pts_tmp) > n_req) {
        crd <- st_coordinates(pts_tmp)
        ord <- order(crd[,1], crd[,2])
        pts_sel <- pts_tmp[ord][seq_len(n_req)]
        break
      }
      delta <- delta - 1
      if (delta < 1) {
        delta <- delta + 2
        if (delta > max_delta) break
      }
    }
    if (is.null(pts_sel) || length(pts_sel) < n_req) {
      base_pt <- st_centroid(st_geometry(talhao)[[1]])
      pts_sel <- st_sfc(rep(base_pt, n_req), crs = st_crs(shape_full))
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
  if (nrow(all_pts) == 0) stop("Nenhum ponto gerado após o processamento dos talhões.")
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}
