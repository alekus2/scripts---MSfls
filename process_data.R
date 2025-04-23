library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         intensidade_proporcao,    # 5 ou 10
                         update_progress,
                         distancia_minima = 200) {
  
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982)

  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = as.character(CD_USO_SOL),
      AREA_HA = as.numeric(AREA_HA)
    )

  shapeb <- shape_full %>%
    st_buffer(-50) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  total_poly    <- n_distinct(shapeb$Index)
  completed     <- 0

  for (idx in unique(shapeb$Index)) {
    talhao    <- filter(shapeb, Index == idx)
    area_ha   <- unique(talhao$AREA_HA)
    subgeoms  <- split_subgeometries(talhao)
    
    for (i in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[i, ]
      area_sg <- as.numeric(st_area(sg))
      if (area_sg < 400) next

      n_req <- max(1, floor(area_ha / intensidade_proporcao))

      # Geração inicial com grade regular
      bb        <- st_bbox(sg)
      grid_pts  <- st_make_grid(
        x        = sg,
        cellsize = c(distancia_minima, distancia_minima),
        offset   = c(bb$xmin + distancia_minima/2, bb$ymin + distancia_minima/2),
        what     = "centers"
      )
      inside    <- st_within(grid_pts, sg, sparse = FALSE)
      pts       <- grid_pts[apply(inside, 1, any)]

      # Se houver mais pontos que o necessário, selecionar apenas os mais centrais
      if (length(pts) > n_req) {
        cr       <- st_coordinates(pts)
        center   <- c(mean(range(cr[,1])), mean(range(cr[,2])))
        dists    <- sqrt((cr[,1] - center[1])^2 + (cr[,2] - center[2])^2)
        pts      <- pts[order(dists)][1:n_req]
      }

      if (length(pts) == 0) next

      coords   <- st_coordinates(pts)
      n_found  <- nrow(coords)
      pts_sf   <- st_sf(
        data.frame(
          Index      = rep(idx,     n_found),
          PROJETO    = rep(talhao$ID_PROJETO, n_found),
          TALHAO     = rep(talhao$TALHAO,    n_found),
          CICLO      = rep(talhao$CICLO,     n_found),
          ROTACAO    = rep(talhao$ROTACAO,   n_found),
          STATUS     = rep("ATIVA",          n_found),
          FORMA      = rep(forma_parcela,    n_found),
          TIPO_INSTA = rep(tipo_parcela,     n_found),
          TIPO_ATUAL = rep(tipo_parcela,     n_found),
          DATA       = rep(Sys.Date(),       n_found),
          DATA_ATUAL = rep(Sys.Date(),       n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = pts
      )
      
      result_points[[paste(idx, i, sep = "_")]] <- pts_sf
    }

    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }

  all_pts <- do.call(rbind, result_points)

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
