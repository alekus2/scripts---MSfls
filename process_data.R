library(sf)
library(dplyr)
library(glue)
process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,      
                         intensidade_amostral,  
                         update_progress) {
  
  # 1) Leitura de parcelas existentes ------------------------------------------------
  parc_exist <- st_read(parc_exist_path) %>% 
    st_transform(31982)
  
  # 2) Preparação do shape e buffer interno -----------------------------------------
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
  
  # 3) Loop por talhão --------------------------------------------------------------
  result_points <- list()
  indices      <- unique(shapeb$Index)
  total_poly   <- length(indices)
  
  for (i_idx in seq_along(indices)) {
    idx     <- indices[i_idx]
    talhao  <- filter(shapeb, Index == idx)
    
    # área total do talhão em hectares
    area_ha <- unique(talhao$AREA_HA)
    
    # número exato de pontos que queremos (pode ser 1)
    n_req <- max(1, ceiling(area_ha / intensidade_amostral))
    
    # grid inicial aproximado
    delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
    bb    <- st_bbox(talhao)
    offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
    
    # 4) Geração iterativa da grid até caber n_req -------------------------------
    pts_all <- NULL
    for (iter in seq_len(30)) {
      grid_pts <- st_make_grid(
        x        = talhao,
        cellsize = c(delta, delta),
        offset   = offset_xy,
        what     = "centers"
      )
      inside   <- st_within(grid_pts, talhao, sparse = FALSE)
      pts_tmp  <- grid_pts[apply(inside, 1, any)]
      
      if (length(pts_tmp) < n_req) {
        delta <- delta * 0.9
        next
      }
      pts_all <- pts_tmp
      break
    }
    
    # se não conseguiu gerar n_req, usa o que gerou ou centroid
    if (is.null(pts_all) || length(pts_all) < n_req) {
      pts_all <- if (!is.null(pts_all) && length(pts_all) > 0) {
        pts_all
      } else {
        st_centroid(talhao)
      }
      # garante pelo menos um
      if (length(pts_all) == 0) pts_all <- st_centroid(talhao)
      # se faltarem, duplica o primeiro
      while (length(pts_all) < n_req) {
        pts_all <- c(pts_all, pts_all[1])
      }
    }
    
    # 5) Seleciona exatamente n_req pontos ordenados ------------------------------
    cr   <- st_coordinates(pts_all)
    ord  <- order(cr[,1], cr[,2])
    sel  <- pts_all[ord][1:n_req]
    
    # 6) Monta o sf com atributos -------------------------------------------------
    coords   <- st_coordinates(sel)
    pts_sf   <- st_sf(
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
        COORD_Y    = coords[,2]
      ),
      geometry = sel
    )
    
    result_points[[idx]] <- pts_sf
    
    # 7) Atualiza progresso -------------------------------------------------------
    update_progress(round(i_idx/total_poly*100, 1))
  }
  
  # 8) Combina todos os pontos gerados --------------------------------------------
  all_pts <- do.call(rbind, result_points)
  
  # 9) Garante mínimo de 2 parcelas por talhão -----------------------------------
  counts <- all_pts %>% 
    st_drop_geometry() %>% 
    count(Index, name = "n_pts")
  
  to_fix <- counts %>% filter(n_pts < 2)
  if (nrow(to_fix) > 0) {
    extras <- lapply(seq_len(nrow(to_fix)), function(i) {
      idx      <- to_fix$Index[i]
      need     <- 2 - to_fix$n_pts[i]
      # ponto base: centroid do talhão original
      base_pt  <- st_centroid(filter(shape_full, Index == idx))
      # monta linhas extras
      df0 <- data.frame(
        Index      = rep(idx, need),
        PROJETO    = rep(base_pt$ID_PROJETO, need),
        TALHAO     = rep(base_pt$TALHAO,    need),
        CICLO      = rep(base_pt$CICLO,     need),
        ROTACAO    = rep(base_pt$ROTACAO,   need),
        STATUS     = rep("ATIVA",           need),
        FORMA      = rep(forma_parcela,     need),
        TIPO_INSTA = rep(tipo_parcela,      need),
        TIPO_ATUAL = rep(tipo_parcela,      need),
        DATA       = rep(Sys.Date(),        need),
        DATA_ATUAL = rep(Sys.Date(),        need),
        COORD_X    = rep(st_coordinates(base_pt)[1], need),
        COORD_Y    = rep(st_coordinates(base_pt)[2], need)
      )
      st_sf(df0, geometry = st_geometry(base_pt)[rep(1, need)])
    })
    all_pts <- bind_rows(all_pts, do.call(rbind, extras))
  }
  
  # 10) Numeração sequencial a partir de parcelas existentes -----------------------
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
