process_data <- function(shape, recomend, parc_exist_path, forma_parcela, 
                         tipo_parcela, distancia.minima, intensidade_amostral, 
                         update_progress) {
  require(sf)
  require(dplyr)
  require(tidyr)

  parc_exist <- st_read(parc_exist_path)
  shape <- st_transform(shape, 31982)
  parc_exist <- st_transform(parc_exist, 31982)
  shape$Index <- paste0(shape$ID_PROJETO, shape$TALHAO)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)

  buffer_distance <- -30
  shapeb <- list()
  empty_indexes <- c()
  for (i in seq_len(nrow(shape))) {
    buffered <- st_buffer(shape[i, ], buffer_distance)
    if (st_is_empty(buffered)) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      shapeb[[i]] <- buffered
    }
  }
  if (length(empty_indexes) > 0) {
    shapeb <- shapeb[-empty_indexes]
  }
  shapeb <- do.call("rbind", shapeb)

  result_points <- list()
  completed_poly_idx <- 0
  total_poly_idx <- length(unique(shapeb$Index))

  for (poly_idx in unique(shapeb$Index)) {
    poly <- shapeb[shapeb$Index == poly_idx, ]
    subgeoms <- split_subgeometries(poly)
    for (i in seq_len(nrow(subgeoms))) {
      sg <- subgeoms[i, ]
      sg_area <- as.numeric(st_area(sg))
      if (sg_area < 400) next

      active_points_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx, ]
      active_points <- st_intersection(st_geometry(active_points_all), st_geometry(sg))

      if (sg_area <= 1000) {
        if (length(active_points) == 0) {
          cell.point <- st_centroid(st_geometry(sg))
          points2 <- st_sf(data.frame(
            Area       = sg_area,
            Index      = poly_idx,
            PROJETO    = poly$ID_PROJETO,
            TALHAO     = poly$TALHAO,
            CICLO      = poly$CICLO,
            ROTACAO    = poly$ROTACAO,
            STATUS     = "ATIVA",
            FORMA      = forma_parcela,
            TIPO_INSTA = tipo_parcela,
            TIPO_ATUAL = tipo_parcela,
            DATA       = Sys.Date(),
            DATA_ATUAL = Sys.Date(),
            COORD_X    = st_coordinates(cell.point)[1],
            COORD_Y    = st_coordinates(cell.point)[2]
          ), geometry = st_geometry(cell.point))
          result_points[[paste(poly_idx, i, sep = "-")]] <- points2
        }
      } else {
        num_parc_recom <- as.numeric(recomend[recomend$Index == poly_idx, "Num.parc"])
        num_parc <- round(num_parc_recom * as.numeric(intensidade_amostral))
        sg_area_ha <- sg_area / 10000
        max_plots <- floor(sg_area_ha / as.numeric(intensidade_amostral))
        num_parc <- ifelse(max_plots < num_parc, max_plots, num_parc)

        grid_spacing <- as.numeric(intensidade_amostral)
        bbox <- st_bbox(sg)
        offset <- c(bbox["xmin"] + grid_spacing/2, bbox["ymin"] + grid_spacing/2)
        grid_all <- st_make_grid(
          sg,
          cellsize = grid_spacing,
          offset   = offset,
          what     = "centers",
          square   = TRUE
        )
        grid_all <- st_sf(geometry = grid_all)
        inside <- st_intersects(grid_all, sg, sparse = FALSE)[,1]
        grid <- grid_all[inside, ]
        if (nrow(grid) == 0) next

        coords <- st_coordinates(grid)
        grid <- grid %>%
          mutate(X = coords[,1], Y = coords[,2]) %>%
          arrange(desc(Y), X)

        num_parc <- min(num_parc, nrow(grid))
        grid_sel <- grid[seq_len(num_parc), ]

        pts <- lapply(seq_len(nrow(grid_sel)), function(j) {
          pt <- grid_sel[j, ]
          st_sf(data.frame(
            Area       = sg_area,
            Index      = poly_idx,
            PROJETO    = poly$ID_PROJETO,
            TALHAO     = poly$TALHAO,
            CICLO      = poly$CICLO,
            ROTACAO    = poly$ROTACAO,
            STATUS     = "ATIVA",
            FORMA      = forma_parcela,
            TIPO_INSTA = tipo_parcela,
            TIPO_ATUAL = tipo_parcela,
            DATA       = Sys.Date(),
            DATA_ATUAL = Sys.Date(),
            COORD_X    = st_coordinates(pt)[1],
            COORD_Y    = st_coordinates(pt)[2]
          ), geometry = st_geometry(pt))
        })
        points2 <- do.call("rbind", pts)
        result_points[[paste(poly_idx, i, sep = "-")]] <- points2
      }

      completed_poly_idx <- completed_poly_idx + 1
    }
    update_progress(round((completed_poly_idx / total_poly_idx) * 100, 2))
  }

  result_points <- do.call("rbind", result_points)
  parcelasinv <- parc_exist %>%
    group_by(PROJETO) %>%
    summarise(numeracao = max(PARCELAS[PARCELAS < 500]), numeracao2 = max(PARCELAS)) %>%
    as.data.frame()

  if (tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP")) {
    parcelasinv <- parcelasinv %>%
      mutate(numeracao.inicial = if_else(numeracao == 499, numeracao2+1, numeracao+1)) %>%
      select(PROJETO, numeracao.inicial)
  } else {
    parcelasinv <- parcelasinv %>%
      mutate(numeracao.inicial = if_else(numeracao < 500, 501, numeracao)) %>%
      select(PROJETO, numeracao.inicial)
  }

  result_points <- result_points %>%
    left_join(parcelasinv, by="PROJETO") %>%
    mutate(numeracao.inicial = replace_na(numeracao.inicial, 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao.inicial)) %>%
    ungroup() %>%
    select(-Area, -numeracao.inicial)

  return(result_points)
}
