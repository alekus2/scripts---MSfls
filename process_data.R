library(sf)
library(dplyr)
library(glue)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,
                         forma_parcela,
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
    n_req <- max(2, ceiling(area_ha / intensidade_amostral))
    delta_base <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta <- delta_base
    bb <- st_bbox(talhao)
    offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)

    found <- FALSE
    for (iter in seq_len(100)) {
      grid_pts <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset_xy, what = "centers")
      inside <- st_within(grid_pts, talhao, sparse = FALSE)
      pts_tmp <- grid_pts[apply(inside, 1, any)]
      if (length(pts_tmp) == n_req) {
        pts_all <- pts_tmp
        found <- TRUE
        break
      } else if (length(pts_tmp) > n_req) {
        delta <- delta + 1
      } else {
        break
      }
    }

    if (!found) {
      delta <- delta - 1
      for (iter in seq_len(100)) {
        grid_pts <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset_xy, what = "centers")
        inside <- st_within(grid_pts, talhao, sparse = FALSE)
        pts_tmp <- grid_pts[apply(inside, 1, any)]
        if (length(pts_tmp) >= n_req) {
          pts_all <- pts_tmp
          break
        }
        delta <- delta - 1
        if (delta <= 1) break
      }
    }

    if (!exists("pts_all")) {
      pts_all <- st_centroid(talhao)
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
        AREA_HA    = rep(area_ha, n_req)
      ),
      geometry = sel
    )

    result_points[[idx]] <- pts_sf
    update_progress(round(i / total_poly * 100, 1))
  }

  all_pts <- do.call(rbind, result_points)

  all_pts <- all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>% 
    ungroup()

  all_pts
}
