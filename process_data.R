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

  # Criar buffer e filtrar polígonos vazios
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
    # Assumindo que 'split_subgeometries' é chamado externamente se necessário
    subs <- st_as_sf(st_cast(poly, "POLYGON")) # Garante que estamos lidando com polígonos simples

    for (i in seq_len(nrow(subs))) {
      sg <- subs[i, ]
      a <- as.numeric(st_area(sg))
      if (a < 400) next

      # Cálculo do número de parcelas e espaçamento
      rec   <- as.numeric(recomend[recomend$Index == poly_idx, "Num.parc"])
      num   <- round(rec * as.numeric(intensidade_amostral))
      ha    <- a / 10000
      maxp  <- floor(ha / (25 * 0.0001))  # 25 m² como área mínima
      num   <- ifelse(maxp < num, maxp, num)

      # Cálculo do espaçamento
      spacing <- sqrt(25)  # Distância mínima entre os pontos para garantir 25 m²

      # Criar a grade centralizada com base no espaçamento
      bb <- st_bbox(sg)
      width <- as.numeric(bb["xmax"] - bb["xmin"])
      height <- as.numeric(bb["ymax"] - bb["ymin"])

      ncol <- floor(width / spacing) + 1
      nrow <- floor(height / spacing) + 1

      lx <- width - (ncol - 1) * spacing
      ly <- height - (nrow - 1) * spacing
      ox <- as.numeric(bb["xmin"]) + lx / 2
      oy <- as.numeric(bb["ymin"]) + ly / 2

      grid_all <- st_make_grid(
        sg,
        cellsize = spacing,
        offset = c(ox, oy),
        what = "centers",
        square = TRUE
      )

      # Filtrar os pontos dentro do polígono
      grid_all <- st_sf(geometry = grid_all)
      inside <- st_intersects(grid_all, sg, sparse = FALSE)[, 1]
      grid <- grid_all[inside, ]

      if (nrow(grid) > 0) {
        # Selecionar os pontos de forma mais sistemática
        num_pontos_desejado <- min(num, nrow(grid))
        if (num_pontos_desejado > 0) {
          n_colunas_sel <- floor(sqrt(num_pontos_desejado * ncol / nrow))
          n_linhas_sel <- ceiling(num_pontos_desejado / n_colunas_sel)

          indices_col <- round(seq(1, ncol, length.out = n_colunas_sel))
          indices_row <- round(seq(1, nrow, length.out = n_linhas_sel))

          indices_grid <- expand.grid(indices_col, indices_row)
          indices_sel <- unique(as.vector(as.matrix(indices_grid)))

          if (length(indices_sel) > num_pontos_desejado) {
            indices_sel <- indices_sel[1:num_pontos_desejado]
          }

          sel <- grid[indices_sel, ]
        } else {
          next
        }
      } else {
        next
      }

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
    update_progress(round((completed_poly_idx / total_poly_idx) * 100, 2))
  }

  rp <- do.call("rbind", result_points)
  inv <- parc_exist %>%
    group_by(PROJETO) %>%
    summarise(numeracao = max(PARCELAS[PARCELAS < 500], na.rm = TRUE),
              numeracao2 = max(PARCELAS, na.rm = TRUE)) %>%
    as.data.frame()

  if (tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP")) {
    inv <- inv %>%
      mutate(numeracao.inicial = if_else(is.na(numeracao) | numeracao == -Inf | numeracao == 499,
                                         ifelse(is.na(numeracao2) | numeracao2 == -Inf, 1, numeracao2 + 1),
                                         numeracao + 1)) %>%
      select(PROJETO, numeracao.inicial)
  } else {
    inv <- inv %>%
      mutate(numeracao.inicial = if_else(is.na(numeracao) | numeracao == -Inf | numeracao < 500, 501, numeracao)) %>%
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