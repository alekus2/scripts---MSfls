library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path, 
                         forma_parcela, tipo_parcela,  
                         distancia.minima,    # distância mínima ao bordo (ex.: 50 m)
                         intensidade_amostral,
                         update_progress) {
  
  # 1) Lê e transforma shapefile de parcelas existentes
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982) %>%
    mutate(Index = paste0(PROJETO, TALHAO))
  
  # 2) Transforma e marca talhões
  shape <- shape %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO))
  
  # 3) Buffer interno igual a -distancia.minima
  buffer_distance <- -abs(distancia.minima)
  shapeb <- shape %>%
    st_buffer(buffer_distance) %>%         # encolhe cada polígono
    filter(!st_is_empty(.))                # descarta polígonos que sumiram
  
  # 4) Prepara lista de saída e progresso
  result_points <- list()
  total_poly   <- length(unique(shapeb$Index))
  completed     <- 0
  
  # 5) Para cada talhão bufferizado
  for (poly_idx in unique(shapeb$Index)) {
    poly     <- filter(shapeb, Index == poly_idx)
    subgeoms <- split_subgeometries(poly) 
    
    for (i in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[i, ]
      area_sg <- as.numeric(st_area(sg))
      
      if (area_sg < 400) next  # pula polígonos minúsculos
      
      # 5.1) talhões pequenos: um ponto no centróide
      if (area_sg <= 1000) {
        pts_sfc <- st_centroid(st_geometry(sg))
        
      } else {
        # 5.2) talhões grandes: grade regular com intensidade_amostral
        pts_sfc <- st_sample(
          x    = st_geometry(sg),
          size = intensidade_amostral,
          type = "regular"
        )
        # reforça: só mantém pontos que realmente caem em 'sg'
        if (length(pts_sfc)) {
          inside <- st_within(pts_sfc, st_geometry(sg), sparse = FALSE)
          pts_sfc <- pts_sfc[apply(inside, 1, any)]
        }
        if (!length(pts_sfc)) next
      }
      
      # 6) monta o sf com atributos
      coords  <- st_coordinates(pts_sfc)
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
        geometry = pts_sfc
      )
      
      result_points[[paste(poly_idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  # 7) consolida e numera parcelas
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
