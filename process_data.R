library(glue)
library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,    
                         intensidade_amostral,
                         update_progress) {
  
  parc_exist <- suppressMessages(st_read(parc_exist_path)) %>% 
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index   = paste0(ID_PROJETO, TALHAO),
      AREA_HA = if ("AREA_HA" %in% names(.)) 
        as.numeric(AREA_HA)
      else as.numeric(st_area(.) / 10000)
    )
  
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  indices    <- unique(shapeb$Index)
  total_poly <- length(indices)
  result_pts <- vector("list", total_poly)
  
  for (i in seq_along(indices)) {
    idx    <- indices[i]
    talhao <- shapeb[shapeb$Index == idx, ]
    if (nrow(talhao)==0) next

    area_ha <- talhao$AREA_HA[1]
    n_req   <- max(2, ceiling(area_ha / intensidade_amostral))

    delta_ideal <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta_min   <- 30
    delta_max   <- distancia_parcelas
    delta       <- min(delta_ideal, delta_max)

    if (delta_min * sqrt(n_req) > sqrt(as.numeric(st_area(talhao)))) {
      message(glue("Talhão {idx}: área muito pequena para {n_req} parcelas com distância menor que 30 m."))
      next
    }
    
    print(glue(
      "Talhão {idx}: n_req={n_req} | delta_ideal={round(delta_ideal,1)} ",
      "| iniciar em {round(delta,1)} (min=30, max={delta_max})"
    ))
    
    max_iter  <- 100
    iter      <- 0
    best_diff <- Inf
    best_pts  <- NULL
    best_delta<- delta
    pts_sel   <- NULL
    
    while (iter < max_iter) {
      bb       <- st_bbox(talhao)
      offset_x <- runif(1, 0, delta)
      offset_y <- runif(1, 0, delta)
      offset   <- c(bb$xmin + offset_x, bb$ymin + offset_y)
      
      grid_all <- st_make_grid(
        talhao,
        cellsize = c(delta, delta),
        offset   = offset,
        what     = "centers"
      ) %>% st_cast("POINT")
      
      inside   <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      pts_tmp  <- grid_all[inside]
      n_pts    <- length(pts_tmp)
      diff     <- abs(n_pts - n_req)

      if (diff < best_diff) {
        best_diff  <- diff
        best_pts   <- pts_tmp
        best_delta <- delta
      }
      
      if (n_pts == n_req) {
        pts_sel <- pts_tmp
        break
      }

      if (n_pts < n_req) {
        delta_novo <- max(delta * 0.95, delta_min)
      } else {
        delta_novo <- min(delta * 1.05, delta_max)
      }
      if (delta_novo == delta) break
      
      delta <- delta_novo
      iter  <- iter + 1
    }
    if (is.null(pts_sel)) {
      if ((delta == delta_min || delta == delta_max) && best_diff <= 1) {
        pts_sel <- best_pts
        delta   <- best_delta
        message(glue(
          "Talhão {idx}: atingiu limite delta={round(delta,1)} m; ",
          "aceitando {length(pts_sel)} pontos (±1)"))
      } else {
        message(glue(
          "Talhão {idx}: não couberam {n_req} parcelas ",
          "com 30 m ≤ delta ≤ {delta_max} m"))
        next
      }
    }
    cr  <- st_coordinates(pts_sel)
    ord <- order(cr[,1], cr[,2])
    sel <- pts_sel[ord][seq_len(n_req)]
    
    df <- tibble(
      Index      = idx,
      PROJETO    = talhao$ID_PROJETO[1],
      TALHAO     = talhao$TALHAO[1],
      CICLO      = talhao$CICLO[1],
      ROTACAO    = talhao$ROTACAO[1],
      STATUS     = "ATIVA",
      FORMA      = forma_parcela,
      TIPO_INSTA = tipo_parcela,
      TIPO_ATUAL = tipo_parcela,
      DATA       = Sys.Date(),
      DATA_ATUAL = Sys.Date(),
      COORD_X    = st_coordinates(sel)[,1],
      COORD_Y    = st_coordinates(sel)[,2],
      AREA_HA    = area_ha
    )
    
    pts_sf <- st_sf(df, geometry = sel, crs = st_crs(shape_full))
    result_pts[[i]] <- pts_sf
    
    update_progress(round(i/total_poly*100,1))
  }
  
  bind_rows(result_pts) %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}
Listening on http://127.0.0.1:5480
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
Talhão 6455002-01: n_req=7 | delta_ideal=170.6 | iniciar em 50 (min=30, max=50)
Talhão 6455002-01: não couberam 7 parcelas com 30 m ??? delta ??? 50 m
Talhão 6436066-01: n_req=2 | delta_ideal=94.9 | iniciar em 50 (min=30, max=50)
Talhão 6436066-01: não couberam 2 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443006-01: n_req=16 | delta_ideal=186.2 | iniciar em 50 (min=30, max=50)
Talhão 6443006-01: não couberam 16 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443010-01: n_req=12 | delta_ideal=181.8 | iniciar em 50 (min=30, max=50)
Talhão 6443010-01: não couberam 12 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443007-01: n_req=20 | delta_ideal=195.6 | iniciar em 50 (min=30, max=50)
Talhão 6443007-01: não couberam 20 parcelas com 30 m ??? delta ??? 50 m
Talhão 6356006-01: n_req=17 | delta_ideal=190.8 | iniciar em 50 (min=30, max=50)
Talhão 6356006-01: não couberam 17 parcelas com 30 m ??? delta ??? 50 m
Talhão 6449009-01: n_req=8 | delta_ideal=152.6 | iniciar em 50 (min=30, max=50)
Talhão 6449009-01: não couberam 8 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443013-01: n_req=15 | delta_ideal=187.8 | iniciar em 50 (min=30, max=50)
Talhão 6443013-01: não couberam 15 parcelas com 30 m ??? delta ??? 50 m
Talhão 6291010-01: n_req=17 | delta_ideal=183.7 | iniciar em 50 (min=30, max=50)
Talhão 6291010-01: não couberam 17 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443002-01: n_req=20 | delta_ideal=186.2 | iniciar em 50 (min=30, max=50)
Talhão 6443002-01: não couberam 20 parcelas com 30 m ??? delta ??? 50 m
Talhão 6428006-01: área muito pequena para 2 parcelas com distância menor que 30 m.
Talhão 6505028-01: n_req=18 | delta_ideal=186.6 | iniciar em 50 (min=30, max=50)
Talhão 6505028-01: não couberam 18 parcelas com 30 m ??? delta ??? 50 m
Talhão 6505026-01: n_req=11 | delta_ideal=175.7 | iniciar em 50 (min=30, max=50)
Talhão 6505026-01: não couberam 11 parcelas com 30 m ??? delta ??? 50 m
Talhão 6505029-01: n_req=13 | delta_ideal=179 | iniciar em 50 (min=30, max=50)
Talhão 6505029-01: não couberam 13 parcelas com 30 m ??? delta ??? 50 m
Talhão 6268029-01: n_req=11 | delta_ideal=173.3 | iniciar em 50 (min=30, max=50)
Talhão 6268029-01: não couberam 11 parcelas com 30 m ??? delta ??? 50 m
Talhão 6268026-01: n_req=9 | delta_ideal=174.8 | iniciar em 50 (min=30, max=50)
Talhão 6268026-01: não couberam 9 parcelas com 30 m ??? delta ??? 50 m
Talhão 6268034-01: área muito pequena para 2 parcelas com distância menor que 30 m.
Talhão 6319009-01: n_req=11 | delta_ideal=152 | iniciar em 50 (min=30, max=50)
Talhão 6319009-01: não couberam 11 parcelas com 30 m ??? delta ??? 50 m
Talhão 6356003-01: n_req=14 | delta_ideal=186.2 | iniciar em 50 (min=30, max=50)
Talhão 6356003-01: não couberam 14 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443008-01: n_req=15 | delta_ideal=183.2 | iniciar em 50 (min=30, max=50)
Talhão 6443008-01: não couberam 15 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443012-01: n_req=5 | delta_ideal=161 | iniciar em 50 (min=30, max=50)
Talhão 6443012-01: não couberam 5 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443015-01: n_req=17 | delta_ideal=193.7 | iniciar em 50 (min=30, max=50)
Talhão 6443015-01: não couberam 17 parcelas com 30 m ??? delta ??? 50 m
Talhão 6387008-01: n_req=14 | delta_ideal=183.9 | iniciar em 50 (min=30, max=50)
Talhão 6387008-01: não couberam 14 parcelas com 30 m ??? delta ??? 50 m
Talhão 6475004-01: n_req=13 | delta_ideal=171.6 | iniciar em 50 (min=30, max=50)
Talhão 6475004-01: não couberam 13 parcelas com 30 m ??? delta ??? 50 m
Talhão 6518017-01: n_req=21 | delta_ideal=170 | iniciar em 50 (min=30, max=50)
Talhão 6518017-01: não couberam 21 parcelas com 30 m ??? delta ??? 50 m
Talhão 6431011-01: n_req=13 | delta_ideal=176.3 | iniciar em 50 (min=30, max=50)
Talhão 6431011-01: não couberam 13 parcelas com 30 m ??? delta ??? 50 m
Talhão 6449001-01: n_req=11 | delta_ideal=105.5 | iniciar em 50 (min=30, max=50)
Talhão 6449001-01: não couberam 11 parcelas com 30 m ??? delta ??? 50 m
Talhão 6431012-01: n_req=13 | delta_ideal=185.1 | iniciar em 50 (min=30, max=50)
Talhão 6431012-01: não couberam 13 parcelas com 30 m ??? delta ??? 50 m
Talhão 6268028-01: n_req=15 | delta_ideal=173.6 | iniciar em 50 (min=30, max=50)
Talhão 6268028-01: não couberam 15 parcelas com 30 m ??? delta ??? 50 m
Talhão 6459015-01: n_req=14 | delta_ideal=169.5 | iniciar em 50 (min=30, max=50)
Talhão 6459015-01: não couberam 14 parcelas com 30 m ??? delta ??? 50 m
Talhão 6443011-01: n_req=7 | delta_ideal=156.2 | iniciar em 50 (min=30, max=50)
Talhão 6443011-01: não couberam 7 parcelas com 30 m ??? delta ??? 50 m
Talhão 6436062-01: n_req=7 | delta_ideal=147.3 | iniciar em 50 (min=30, max=50)
Talhão 6436062-01: não couberam 7 parcelas com 30 m ??? delta ??? 50 m
Talhão 6431048-01: n_req=19 | delta_ideal=184.8 | iniciar em 50 (min=30, max=50)
Talhão 6431048-01: não couberam 19 parcelas com 30 m ??? delta ??? 50 m
Talhão 6436047-01: n_req=15 | delta_ideal=189.6 | iniciar em 50 (min=30, max=50)
Talhão 6436047-01: não couberam 15 parcelas com 30 m ??? delta ??? 50 m
Talhão 6518002-01: n_req=14 | delta_ideal=183.3 | iniciar em 50 (min=30, max=50)
Talhão 6518002-01: não couberam 14 parcelas com 30 m ??? delta ??? 50 m
Talhão 6518001-01: n_req=20 | delta_ideal=190 | iniciar em 50 (min=30, max=50)
Talhão 6518001-01: não couberam 20 parcelas com 30 m ??? delta ??? 50 m
Talhão 6459024-01: n_req=12 | delta_ideal=177.8 | iniciar em 50 (min=30, max=50)
Talhão 6459024-01: não couberam 12 parcelas com 30 m ??? delta ??? 50 m
Talhão 6505035-01: n_req=13 | delta_ideal=169.1 | iniciar em 50 (min=30, max=50)
Talhão 6505035-01: não couberam 13 parcelas com 30 m ??? delta ??? 50 m
Aviso: Error in group_by: Must group by variables found in `.data`.
x Column `Index` is not found.
  92: <Anonymous>
  91: signalCondition
  90: signal_abort
  89: abort
  88: group_by_prepare
  87: group_by.data.frame
  86: group_by
  85: mutate
  84: ungroup
  83: %>%
  82: process_data [src/process_data.R#143]
  81: observe [src/server.R#74]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp


oque deu errado nesse codigo?
