# process_data.R
library(sf)
library(dplyr)

# distância (m) a partir da intensidade (ha)
calc_spacing <- function(intensidade_ha) {
  sqrt(intensidade_ha * 10000)
}

process_data <- function(shape, recomend, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         intensidade_amostral, update_progress) {

  parc_exist <- st_read(parc_exist_path, quiet = TRUE)
  shape      <- st_transform(shape, 31982)
  parc_exist <- st_transform(parc_exist, 31982)
  shape$Index      <- paste0(shape$ID_PROJETO, shape$TALHAO)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)

  # cria buffer interno de –30 m
  buffered <- lapply(seq_len(nrow(shape)), function(i) {
    b <- st_buffer(shape[i, ], -30)
    if (st_is_empty(b)) NULL else b
  }) %>% compact() %>% do.call("rbind", .)

  result_pts <- list()
  total <- length(unique(buffered$Index))
  done  <- 0

  for (idx in unique(buffered$Index)) {
    sg_all <- buffered[buffered$Index == idx, ]
    # para cada subgeometria do polígono
    subs <- split_subgeometries(sg_all)
    for (j in seq_len(nrow(subs))) {
      sg   <- subs[j, ]
      area <- as.numeric(st_area(sg))
      if (area < 400) next

      # decide qte de parcelas
      n_parc <- recomend$Num.parc[recomend$Index == idx]

      # calcula espaçamento em metros
      spacing <- calc_spacing(intensidade_amostral)

      # centraliza grade
      bb <- st_bbox(sg)
      w  <- bb["xmax"] - bb["xmin"]
      h  <- bb["ymax"] - bb["ymin"]
      ncol <- floor(w/spacing) + 1
      nrow <- floor(h/spacing) + 1
      lx <- w - (ncol - 1)*spacing
      ly <- h - (nrow - 1)*spacing
      ox <- bb["xmin"] + lx/2
      oy <- bb["ymin"] + ly/2

      grid_all <- st_make_grid(
        sg,
        cellsize = spacing,
        offset   = c(ox, oy),
        what     = "centers",
        square   = TRUE
      ) %>% st_sf()

      inside <- st_intersects(grid_all, sg, sparse = FALSE)[,1]
      grid    <- grid_all[inside, , drop = FALSE]
      if (nrow(grid) < n_parc) next

      # ordena e seleciona primeiros n_parc
      coords <- st_coordinates(grid)
      grid   <- grid %>%
        mutate(COORD_X = coords[,1], COORD_Y = coords[,2]) %>%
        arrange(desc(COORD_Y), COORD_X) %>%
        slice_head(n = n_parc)

      # atributos finais
      grid$Index      <- idx
      grid$PROJETO    <- sg$ID_PROJETO
      grid$TALHAO     <- sg$TALHAO
      grid$CICLO      <- sg$CICLO
      grid$ROTACAO    <- sg$ROTACAO
      grid$STATUS     <- "ATIVA"
      grid$FORMA      <- forma_parcela
      grid$TIPO_INSTA <- tipo_parcela
      grid$TIPO_ATUAL <- tipo_parcela
      grid$DATA       <- Sys.Date()
      grid$DATA_ATUAL <- Sys.Date()
      grid$PARCELAS   <- seq_len(nrow(grid))

      result_pts[[paste(idx, j, sep = "_")]] <- grid
      done <- done + 1
    }
    update_progress(round(done/total * 100, 1))
  }

  do.call("rbind", result_pts)
}
