library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,      # em metros, ex: 50
                         intensidade_amostral,  # X em “1 ponto a cada X ha”
                         update_progress) {     # callback para progresso

  # 1) lê e reprojeta as parcelas existentes
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982)

  # 2) prepara shapefile principal com AREA_HA e Index = CD_USO_SOL
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = as.character(CD_USO_SOL),
      AREA_HA = as.numeric(AREA_HA)
    )

  # 3) aplica buffer interno usando o parâmetro distancia.minima
  buf_dist <- -abs(distancia.minima)
  shapeb   <- shape_full %>%
    st_buffer(buf_dist) %>%
    filter(!st_is_empty(geometry))

  result_points <- list()
  total_poly   <- n_distinct(shapeb$Index)
  completed    <- 0

  # 4) loop por cada talhão (Index)
  for (idx in unique(shapeb$Index)) {
    talhao   <- filter(shapeb, Index == idx)
    area_ha  <- unique(talhao$AREA_HA)
    subgeo   <- split_subgeometries(talhao)

    for (i in seq_len(nrow(subgeo))) {
      sg      <- subgeo[i, ]
      area_sg <- as.numeric(st_area(sg))
      if (area_sg < 400) next

      # 5a) calcula quantos pontos: 1 por intensidade_amostral ha
      n_req <- max(1, floor(area_ha / intensidade_amostral))

      # 5b) define espaçamento e offset para grade
      delta     <- sqrt(area_sg / n_req)
      bb        <- st_bbox(sg)
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)

      # 5c) gera grid de pontos-centro
      grid_pts <- st_make_grid(sg,
                               cellsize = c(delta, delta),
                               offset   = offset_xy,
                               what     = "centers")
      inside   <- st_within(grid_pts, sg, sparse = FALSE)
      pts      <- grid_pts[apply(inside, 1, any)]

      # 5d) fallback para 1:10 ha se faltar pontos
      if (length(pts) < n_req) {
        n_req <- max(1, floor(area_ha / 10))
        delta     <- sqrt(area_sg / n_req)
        offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
        grid_pts  <- st_make_grid(sg,
                                  cellsize = c(delta, delta),
                                  offset   = offset_xy,
                                  what     = "centers")
        inside    <- st_within(grid_pts, sg, sparse = FALSE)
        pts       <- grid_pts[apply(inside, 1, any)]
      }
      if (length(pts) == 0) next

      # 5e) ordena, seleciona n_req e monta sf
      cr       <- st_coordinates(pts)
      ord      <- order(cr[,1], cr[,2])
      sel_pts  <- pts[ord][ seq_len(min(length(pts), n_req)) ]

      coords   <- st_coordinates(sel_pts)
      n_found  <- nrow(coords)
      pts_sf   <- st_sf(
        data.frame(
          Index      = rep(idx,      n_found),
          PROJETO    = rep(talhao$ID_PROJETO, n_found),
          TALHAO     = rep(talhao$TALHAO,    n_found),
          CICLO      = rep(talhao$CICLO,     n_found),
          ROTACAO    = rep(talhao$ROTACAO,   n_found),
          STATUS     = rep("ATIVA",           n_found),
          FORMA      = rep(forma_parcela,     n_found),
          TIPO_INSTA = rep(tipo_parcela,      n_found),
          TIPO_ATUAL = rep(tipo_parcela,      n_found),
          DATA       = rep(Sys.Date(),        n_found),
          DATA_ATUAL = rep(Sys.Date(),        n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel_pts
      )

      result_points[[paste(idx, i, sep = "_")]] <- pts_sf
    }

    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }

  # 6) combina todos os pontos
  all_pts <- do.call(rbind, result_points)

  # 7) numeração sequencial a partir de parc_exist
  parcelasinv <- parc_exist %>%
    st_drop_geometry() %>%
    group_by(PROJETO) %>%
    summarise(
      max_antiga = max(PARCELAS[PARCELAS < 500], na.rm = TRUE),
      max_geral  = max(PARCELAS, na.rm = TRUE)
    ) %>%
    mutate(
      numeracao_inicial = if_else(
        tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP"),
        if_else(max_antiga == 499, max_geral + 1, max_antiga + 1),
        if_else(max_antiga < 500, 501, max_antiga + 1)
      )
    ) %>%
    select(PROJETO, numeracao_inicial)

  all_pts <- all_pts %>%
    left_join(parcelasinv, by = "PROJETO") %>%
    replace_na(list(numeracao_inicial = 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao_inicial)) %>%
    ungroup() %>%
    select(-numeracao_inicial)

  return(all_pts)
}
