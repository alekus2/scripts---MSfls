library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path, 
                         forma_parcela, tipo_parcela,  
                         distancia.minima,      # aqui não usamos, fixo -30 m
                         intensidade_amostral,  # X em “1 ponto a cada X ha”
                         update_progress) {
  
  # 1) Lê e transforma as parcelas existentes
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982) %>%
    mutate(Index = paste0(PROJETO, TALHAO))
  
  # 2) Transforma e marca os talhões originais
  shape <- shape %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO))
  
  # 3) Buffer interno fixo de -30 m (retração)
  shapeb <- shape %>%
    st_buffer(-30) %>%                 # encolhe 30 m por toda a volta
    filter(!st_is_empty(geometry))     # descarta talhões que sumiriam
  
  result_points <- list()
  total_poly   <- n_distinct(shapeb$Index)
  completed     <- 0
  
  # 4) Para cada talhão bufferizado
  for (poly_idx in unique(shapeb$Index)) {
    poly     <- filter(shapeb, Index == poly_idx)
    subgeoms <- split_subgeometries(poly)
    
    for (i in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[i, ]
      area_sg <- as.numeric(st_area(sg))    # área em m²
      if (area_sg < 400) next               # ignora pedaços pequenininhos
      
      # a) quantos pontos em 1 por X ha?
      area_ha       <- area_sg / 10000
      n_req         <- max(1, floor(area_ha / intensidade_amostral))
      
      # b) função que gera e filtra centros de grade
      make_pts <- function(n_pts) {
        # spacing aproximado para obter n_pts
        dx   <- sqrt(area_sg / n_pts)
        grid <- st_make_grid(sg, cellsize = c(dx, dx), what = "centers")
        inside <- st_within(grid, sg, sparse = FALSE)
        pts    <- grid[apply(inside, 1, any)]
        # ordena por X depois Y e seleciona n_pts
        if (length(pts) > 1) {
          cr <- st_coordinates(pts)
          ord <- order(cr[,1], cr[,2])
          pts <- pts[ord]
        }
        pts[ seq_len(min(length(pts), n_pts)) ]
      }
      
      # c) tenta gerar com n_req
      pts_sfc <- make_pts(n_req)
      
      # d) se não couber tudo, faz fallback para razão 1:10
      if (length(pts_sfc) < n_req) {
        fallback_ha <- 10
        n_req2      <- max(1, floor(area_ha / fallback_ha))
        pts_sfc     <- make_pts(n_req2)
      }
      
      if (length(pts_sfc) == 0) next
      
      # e) monta o sf de saída com atributos
      coords  <- st_coordinates(pts_sfc)
      n_found <- nrow(coords)
      pts_sf  <- st_sf(
        data.frame(
          Index      = rep(poly$Index, n_found),
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
        geometry = pts_sfc
      )
      
      result_points[[paste(poly_idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  # 5) consolida todos os pontos
  all_pts <- do.call(rbind, result_points)
  
  # 6) numeração sequencial sem geometria em parc_exist
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
