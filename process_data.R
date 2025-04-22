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
    b <- st_buffer(shape[i, ], buffer_distance)
    if (st_is_empty(b)) {
      empty_indexes <- c(empty_indexes, i)
    } else {
      shapeb[[i]] <- b
    }
  }
  if (length(empty_indexes) > 0) shapeb <- shapeb[-empty_indexes]
  shapeb <- do.call("rbind", shapeb)

  result_points <- list()
  completed_poly_idx <- 0
  total_poly_idx <- length(unique(shapeb$Index))

  for (poly_idx in unique(shapeb$Index)) {
    poly <- shapeb[shapeb$Index == poly_idx, ]
    subs <- split_subgeometries(poly)
    for (i in seq_len(nrow(subs))) {
      sg <- subs[i, ]
      a <- as.numeric(st_area(sg))
      if (a < 400) next

      act_all <- parc_exist[parc_exist$STATUS == "ATIVA" & parc_exist$Index == poly_idx, ]
      act_int <- st_intersection(st_geometry(act_all), st_geometry(sg))

      if (a <= 1000) {
        if (length(act_int) == 0) {
          cpt <- st_centroid(st_geometry(sg))
          p <- st_sf(data.frame(
            Area       = a,
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
            COORD_X    = st_coordinates(cpt)[1],
            COORD_Y    = st_coordinates(cpt)[2]
          ), geometry = st_geometry(cpt))
          result_points[[paste(poly_idx, i, sep = "-")]] <- p
        }
      } else {
        rec  <- as.numeric(recomend[recomend$Index == poly_idx, "Num.parc"])
        num  <- round(rec * as.numeric(intensidade_amostral))
        ha   <- a / 10000
        maxp <- floor(ha / as.numeric(intensidade_amostral))
        num  <- ifelse(maxp < num, maxp, num)

        spacing <- as.numeric(intensidade_amostral)
        bb      <- st_bbox(sg)
        width   <- as.numeric(bb["xmax"] - bb["xmin"])
        height  <- as.numeric(bb["ymax"] - bb["ymin"])
        ncol    <- floor(width  / spacing) + 1
        nrow    <- floor(height / spacing) + 1
        lx      <- width  - (ncol - 1) * spacing
        ly      <- height - (nrow - 1) * spacing
        ox      <- as.numeric(bb["xmin"]) + lx/2
        oy      <- as.numeric(bb["ymin"]) + ly/2

        grid_all <- st_make_grid(
          sg,
          cellsize = spacing,
          offset   = c(ox, oy),
          what     = "centers",
          square   = TRUE
        )
        grid_all <- st_sf(geometry = grid_all)
        inside  <- st_intersects(grid_all, sg, sparse = FALSE)[,1]
        grid    <- grid_all[inside, ]
        if (nrow(grid) == 0) next

        crds <- st_coordinates(grid)
        grid <- grid %>% mutate(X = crds[,1], Y = crds[,2]) %>%
          arrange(desc(Y), X)

        num  <- min(num, nrow(grid))
        sel  <- grid[seq_len(num), ]

        pts <- lapply(seq_len(nrow(sel)), function(j) {
          pt <- sel[j, ]
          st_sf(data.frame(
            Area       = a,
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
        p2 <- do.call("rbind", pts)
        result_points[[paste(poly_idx, i, sep = "-")]] <- p2
      }

      completed_poly_idx <- completed_poly_idx + 1
    }
    update_progress(round((completed_poly_idx / total_poly_idx) * 100, 2))
  }

  rp <- do.call("rbind", result_points)
  inv <- parc_exist %>%
    group_by(PROJETO) %>%
    summarise(numeracao = max(PARCELAS[PARCELAS < 500]),
              numeracao2 = max(PARCELAS)) %>%
    as.data.frame()

  if (tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP")) {
    inv <- inv %>%
      mutate(numeracao.inicial = if_else(numeracao == 499, numeracao2+1, numeracao+1)) %>%
      select(PROJETO, numeracao.inicial)
  } else {
    inv <- inv %>%
      mutate(numeracao.inicial = if_else(numeracao < 500, 501, numeracao)) %>%
      select(PROJETO, numeracao.inicial)
  }

  rp <- rp %>%
    left_join(inv, by = "PROJETO") %>%
    mutate(numeracao.inicial = replace_na(numeracao.inicial, 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao.inicial)) %>%
    ungroup() %>%
    select(-Area, -numeracao.inicial)

  return(rp)
}
