library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path, 
                         forma_parcela, tipo_parcela,  
                         distancia.minima, intensidade_amostral,
                         update_progress) {
  
  # 1) Leitura e transformação das parcelas existentes
  parc_exist <- st_read(parc_exist_path)
  parc_exist <- st_transform(parc_exist, 31982)
  parc_exist$Index <- paste0(parc_exist$PROJETO, parc_exist$TALHAO)
  
  # 2) Transformação e marcação dos talhões de shape
  shape <- st_transform(shape, 31982)
  shape$Index <- paste0(shape$ID_PROJETO, shape$TALHAO)
  
  # 3) Buffer interno fixo de -30 m
  buffer_distance <- -30
  shapeb_list <- lapply(seq_len(nrow(shape)), function(i) {
    buf <- st_buffer(shape[i, ], buffer_distance)
    if (st_is_empty(buf)) NULL else buf
  })
  shapeb <- do.call(rbind, Filter(NROW, shapeb_list))
  
  # 4) Preparação de saída e progresso
  result_points <- list()
  total_poly   <- length(unique(shapeb$Index))
  completed     <- 0
  
  # 5) Para cada talhão (agrupado por Index)
  for (poly_idx in unique(shapeb$Index)) {
    poly      <- shapeb[shapeb$Index == poly_idx, ]
    subgeoms  <- split_subgeometries(poly)
    
    for (j in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[j, ]
      area_sg <- as.numeric(st_area(sg))
      
      # 5.1) descarta áreas < 400 m²
      if (area_sg < 400) next
      
      # 5.2) 400–1000 m² → centróide
      if (area_sg <= 1000) {
        centroid <- st_centroid(st_geometry(sg))
        pts_sf <- st_sf(
          data.frame(
            Index      = poly_idx,
            PROJETO    = poly$ID_PROJETO,
            TALHAO     = poly$TALHAO,
            CICLO      = poly$CICLO,
            ROTACAO    = poly$ROTACAO,
            STATUS     = "ATIVA",
            FORMA      = forma_parcela,
            TIPO_INSTA = tipo_parcela,
            TIPO_ATUAL = tipo_parcela,
            DATA       = Sys.Date(),
            DATA_ATUAL = Sys.Date(),
            COORD_X    = st_coordinates(centroid)[,1],
            COORD_Y    = st_coordinates(centroid)[,2]
          ),
          geometry = centroid
        )
        
      } else {
        # 5.3) >1000 m² → grade regular com intensidade_amostral
        # (1) cria pontos numa grade regular sobre a geometria reduzida
        pts_sfc <- st_sample(
          x    = st_geometry(sg),
          size = intensidade_amostral,
          type = "regular"
        )
        
        # (2) filtra de novo para garantir que só fique INSIDE do buffer
        if (length(pts_sfc)) {
          inside_mat <- st_within(pts_sfc, st_geometry(sg), sparse = FALSE)
          pts_sfc     <- pts_sfc[apply(inside_mat, 1, any)]
        }
        
        n_found <- length(pts_sfc)
        if (n_found == 0) next
        
        # (3) monta o sf com atributos
        coords <- st_coordinates(pts_sfc)
        pts_sf <- st_sf(
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
      }
      
      result_points[[paste(poly_idx, j, sep = "_")]] <- pts_sf
    }
    
    # atualiza progresso
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  # 6) junta tudo num único sf
  all_pts <- do.call(rbind, result_points)
  
  # 7) numeração sequencial de parcelas (sem geometria em parc_exist)
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
