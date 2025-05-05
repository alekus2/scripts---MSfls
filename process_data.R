library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         intensidade_amostral,
                         update_progress) {
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = paste0(ID_PROJETO, TALHAO),
      AREA_HA = as.numeric(AREA_HA)
    )
  
  buf_dist <- -abs(distancia.minima)
  shapeb   <- shape_full %>%
    st_buffer(buf_dist) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  total_poly    <- n_distinct(shapeb$Index)
  completed     <- 0
  
  for (idx in unique(shapeb$Index)) {
    talhao   <- filter(shapeb, Index == idx)
    area_ha  <- unique(talhao$AREA_HA)
    print(paste("Processando índice:", idx, "Área total (ha):", area_ha))
    
    subgeo <- split_subgeometries(talhao)
    if (nrow(subgeo) == 0) {
      print(paste("Subgeometria vazia para o índice:", idx))
      next
    }
    
    for (i in seq_len(nrow(subgeo))) {
      sg <- subgeo[i, ]
      # calcula área da subgeometria em m²
      area_sg <- as.numeric(st_area(sg))
      print(paste("Processando subgeometria:", i, "Área (m2):", round(area_sg, 2)))
      
      # pontos por intensidade (ha → m2)
      n_req <- ceiling((area_ha * 10000) / intensidade_amostral)
      n_req <- min(n_req, floor(area_sg / intensidade_amostral))
      print(paste("Número de pontos requeridos:", n_req))
      if (n_req < 1) {
        print("Menos de 1 ponto necessário; pulando.")
        next
      }
      
      delta     <- sqrt(area_sg / n_req)
      bb        <- st_bbox(sg)
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
      
      # gera e filtra grid até ter candidatos suficientes
      cand <- st_sfc(crs = st_crs(sg))
      for (iter in seq_len(20)) {
        grid_pts <- st_make_grid(
          x        = sg,
          cellsize = c(delta, delta),
          offset   = offset_xy,
          what     = "centers"
        )
        if (length(grid_pts) == 0) {
          delta <- delta * 0.95
          next
        }
        inside_lst <- st_within(grid_pts, sg)
        idx_keep   <- lengths(inside_lst) > 0
        cand       <- grid_pts[idx_keep]
        print(paste0("Iter ", iter, ": candidatos = ", length(cand)))
        if (length(cand) >= n_req) {
          cand <- cand[seq_len(n_req * 2)]
          break
        }
        delta <- delta * 0.95
      }
      if (length(cand) == 0) {
        print("Nenhum candidato encontrado; pulando.")
        next
      }
      
      # seleciona automaticamente garantindo distância mínima
      min_dist <- delta * 0.8
      sel <- list()
      for (pt in cand) {
        if (length(sel) == 0) {
          sel <- list(pt)
        } else {
          dists <- sapply(sel, function(x) as.numeric(st_distance(x, pt)))
          if (all(dists >= min_dist)) sel <- append(sel, list(pt))
        }
        if (length(sel) == n_req) break
      }
      if (length(sel) < 1) {
        print("Nenhum ponto selecionado; pulando.")
        next
      }
      
      sel    <- st_sfc(sel, crs = st_crs(sg))
      coords <- st_coordinates(sel)
      n_found <- nrow(coords)
      pts_sf <- st_sf(
        data.frame(
          Index      = rep(idx, n_found),
          PROJETO    = rep(talhao$ID_PROJETO, n_found),
          TALHAO     = rep(talhao$TALHAO, n_found),
          CICLO      = rep(talhao$CICLO, n_found),
          ROTACAO    = rep(talhao$ROTACAO, n_found),
          STATUS     = rep("ATIVA", n_found),
          FORMA      = rep(forma_parcela, n_found),
          TIPO_INSTA = rep(tipo_parcela, n_found),
          TIPO_ATUAL = rep(tipo_parcela, n_found),
          DATA       = rep(Sys.Date(), n_found),
          DATA_ATUAL = rep(Sys.Date(), n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel
      )
      
      result_points[[paste(idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  if (length(result_points) == 0) {
    print("Nenhum ponto foi adicionado a result_points.")
    return(NULL)
  }
  
  all_pts <- do.call(rbind, result_points) %>%
    group_by(Index) %>%
    mutate(PARCELAS = row_number()) %>%
    ungroup()
  
  all_pts
}
