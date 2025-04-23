library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path, 
                         forma_parcela, tipo_parcela,  
                         distancia.minima,      # não usado, buffer fixo de 30 m
                         intensidade_amostral,  # X em “1 ponto a cada X ha”
                         update_progress) {
  
  # 1) lê as parcelas existentes e marca Index = TALHAO
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982) %>%
    mutate(Index = as.character(TALHAO))
  
  # 2) transforma shape e marca Index = TALHAO
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(Index   = as.character(TALHAO),
           AREA_HA = as.numeric(AREA_HA))  # garante numérico
  
  # 3) tabela de lookup de área (ha) por talhão
  area_lookup <- shape_full %>%
    st_drop_geometry() %>%
    select(Index, AREA_HA) %>%
    distinct()
  
  # 4) aplica buffer interno fixo de -30 m
  shapeb <- shape_full %>%
    st_buffer(-30) %>%
    filter(!st_is_empty(geometry))
  
  result_points <- list()
  total_poly   <- n_distinct(shapeb$Index)
  completed     <- 0
  
  # 5) para cada talhão bufferizado
  for (poly_idx in unique(shapeb$Index)) {
    poly     <- filter(shapeb, Index == poly_idx)
    subgeoms <- split_subgeometries(poly)
    orig_ha  <- area_lookup$AREA_HA[area_lookup$Index == poly_idx]
    
    for (i in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[i, ]
      area_sg <- as.numeric(st_area(sg))
      if (area_sg < 400) next  # pula pedaços pequenos demais
      
      # a) quantos pontos em 1 por X ha?
      n_req <- max(1, floor(orig_ha / intensidade_amostral))
      
      # b) cria GRID de centros com espaçamento 200 m
      grid  <- st_make_grid(
        x       = sg,
        cellsize= c(200, 200),
        what    = "centers"
      )
      # filtra só os que caem dentro do polígono
      inside <- st_within(grid, sg, sparse = FALSE)
      pts    <- grid[apply(inside, 1, any)]
      if (!length(pts)) next
      
      # c) ordena por X então Y
      cr  <- st_coordinates(pts)
      ord <- order(cr[,1], cr[,2])
      pts <- pts[ord]
      
      # d) se não couberem n_req, faz fallback p/ 1:10 ha
      if (length(pts) < n_req) {
        n_req <- max(1, floor(orig_ha / 10))
      }
      
      # e) seleciona os primeiros n_req pontos
      sel_pts <- pts[ seq_len(min(length(pts), n_req)) ]
      coords  <- st_coordinates(sel_pts)
      
      # f) monta o sf com atributos
      n_found <- nrow(coords)
      pts_sf  <- st_sf(
        data.frame(
          Index      = rep(poly_idx, n_found),
          PROJETO    = rep(poly$ID_PROJETO, n_found),
          TALHAO     = rep(poly$TALHAO, n_found),
          CICLO      = rep(poly$CICLO, n_found),
          ROTACAO    = rep(poly$ROTACAO, n_found),
          STATUS     = rep("ATIVA", n_found),
          FORMA      = rep(forma_parcela, n_found),
          TIPO_INSTA = rep(tipo_parcela, n_found),
          TIPO_ATUAL = rep(tipo_parcela, n_found),
          DATA       = rep(Sys.Date(), n_found),
          DATA_ATUAL = rep(Sys.Date(), n_found),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel_pts
      )
      
      result_points[[paste(poly_idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  # 6) combina todos os pontos gerados
  all_pts <- do.call(rbind, result_points)
  
  # 7) recalcula numeração sem geometria em parc_exist
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
