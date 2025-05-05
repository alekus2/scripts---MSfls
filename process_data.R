library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         intensidade_amostral = NULL,
                         hectares_por_ponto   = NULL,
                         update_progress) {
  # determina quantos pontos por hectare
  if (!is.null(hectares_por_ponto)) {
    pontos_por_ha <- 1 / hectares_por_ponto
  } else if (!is.null(intensidade_amostral)) {
    pontos_por_ha <- intensidade_amostral
  } else {
    stop("Você precisa fornecer 'intensidade_amostral' ou 'hectares_por_ponto'")
  }
  message(">> pontos_por_ha = ", pontos_por_ha)
  
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
    talhao  <- filter(shapeb, Index == idx)
    area_ha <- unique(talhao$AREA_HA)
    message("Processando índice: ", idx, " — Área total (ha): ", area_ha)
    
    # calcula total de pontos para o talhão
    n_req_total <- floor(area_ha * pontos_por_ha)
    message("  n_req_total = ", n_req_total)
    if (n_req_total < 1) {
      message("  <1 ponto no talhão; pulando ", idx)
      next
    }
    
    subgeo <- split_subgeometries(talhao)
    if (nrow(subgeo) == 0) {
      message("  sem subgeometrias em ", idx)
      next
    }
    
    # distribui proporcionalmente aos pedaços
    areas_sg_ha <- as.numeric(st_area(subgeo)) / 10000
    proporcao   <- areas_sg_ha / sum(areas_sg_ha)
    n_req_vec   <- round(n_req_total * proporcao)
    n_req_vec[n_req_vec < 1] <- 0
    
    for (i in seq_len(nrow(subgeo))) {
      sg     <- subgeo[i, ]
      n_req  <- n_req_vec[i]
      area_m2 <- as.numeric(st_area(sg))
      message("  subgeom ", i, ": área (m²)=", round(area_m2,1),
              " → pontos=", n_req)
      if (n_req < 1) next
      
      delta     <- sqrt(area_m2 / n_req)
      bb        <- st_bbox(sg)
      offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
      
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
        keep       <- lengths(inside_lst) > 0
        cand       <- grid_pts[keep]
        message("    iter ", iter, ": candidatos=", length(cand))
        if (length(cand) >= n_req) {
          cand <- cand[seq_len(n_req * 2)]
          break
        }
        delta <- delta * 0.95
      }
      if (length(cand) < 1) next
      
      min_dist <- delta * 0.8
      sel      <- list()
      for (pt in cand) {
        if (length(sel) == 0) {
          sel <- list(pt)
        } else {
          dists <- sapply(sel, function(x) as.numeric(st_distance(x, pt)))
          if (all(dists >= min_dist)) sel <- append(sel, list(pt))
        }
        if (length(sel) == n_req) break
      }
      if (length(sel) < 1) next
      
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
    message("Nenhum ponto foi gerado.")
    return(NULL)
  }
  
  do.call(rbind, result_points) %>%
    group_by(Index) %>%
    mutate(PARCELAS = row_number()) %>%
    ungroup()
}
