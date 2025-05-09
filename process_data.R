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
  print(head(shape_full))
  
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
    
    # número exato de pontos que queremos no talhão inteiro
    n_req <- max(1, floor(area_ha / intensidade_amostral))
    
    # se não couber nem 1 ponto, pula
    if (n_req <= 0) {
      message(glue("Talhão {idx}: área muito pequena, pulando."))
      update_progress(round(i_idx/total_poly*100, 1))
      next
    }
    
    # grid inicial aproximado
    delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
    bb    <- st_bbox(talhao)
    offset_xy <- c(bb$xmin + delta/2, bb$ymin + delta/2)
    
    # 4) Geração iterativa da grid até caber n_req -------------------------------
    pts_all <- NULL
    for (iter in seq_len(20)) {
      grid_pts <- st_make_grid(
        x        = talhao,
        cellsize = c(delta, delta),
        offset   = offset_xy,
        what     = "centers"
      )
      inside   <- st_within(grid_pts, talhao, sparse = FALSE)
      pts_tmp  <- grid_pts[apply(inside, 1, any)]
      
      if (length(pts_tmp) >= n_req) {
        pts_all <- pts_tmp
        break
      }
      delta <- delta * 0.95
    }
    
    # se mesmo assim não coube, pula o talhão
    if (is.null(pts_all) || length(pts_all) < n_req) {
      message(glue(
        "Talhão {idx} só comporta {length(pts_all)} pontos (precisava de {n_req}). Pulando."
      ))
      update_progress(round(i_idx/total_poly*100, 1))
      next
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
  
  # 9) Numeração sequencial a partir de parcelas existentes -----------------------
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
