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
    if (nrow(talhao) == 0) next
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) next

    area_ha <- talhao$AREA_HA[1]
    n_req   <- max(2, ceiling(area_ha / intensidade_amostral))

    delta_max <- sqrt(as.numeric(st_area(talhao)) / n_req)
    delta     <- delta_max
    delta_min <- max(distancia_parcelas, 30)  
    
    print(glue(
      "Talhão: {idx} | n_req: {n_req} | delta_inicial: {round(delta,2)} m | ",
      "INT_amostral: {intensidade_amostral} | Área: {round(area_ha,2)} ha"
    ))

    max_iter  <- 100
    iter      <- 0
    best_diff <- Inf
    best_pts  <- NULL
    best_delta<- delta
    pts_sel   <- NULL

    while (iter < max_iter) {
      # cria grid de centros
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

      if (delta_novo == delta) {
        message(glue(
          "Talhão {idx}: não é possível encaixar {n_req} parcelas ",
          "com distância em [{round(delta_min,1)}, {round(delta_max,1)}] m"
        ))
        break
      }
      
      delta <- delta_novo
      iter  <- iter + 1
    }

    if (is.null(pts_sel)) {
      if (best_diff <= 1) {
        pts_sel <- best_pts
        delta   <- best_delta
        message(glue(
          "Talhão {idx}: aceitando {length(pts_sel)} pontos ",
          "(margem ±1) com delta = {round(delta,1)} m"
        ))
      } else {
        message(glue(
          "Talhão {idx}: impossível alocar {n_req} parcelas ",
          "com distância ≥ {round(delta_min,1)} m"
        ))
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

    update_progress(round(i / total_poly * 100, 1))
  }

  bind_rows(result_pts) %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}

Listening on http://127.0.0.1:6314
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
TalhÃ£o: 6455002-01 | n_req: 7 | delta_inicial: 170.59 m | INT_amostral: 5 | Ãrea: 34.17 ha
TalhÃ£o: 6436066-01 | n_req: 2 | delta_inicial: 94.86 m | INT_amostral: 5 | Ãrea: 8.7 ha
TalhÃ£o 6436066-01: nÃ£o Ã© possÃ­vel encaixar 2 parcelas com distÃ¢ncia em [200, 94.9] m
TalhÃ£o 6436066-01: aceitando 1 pontos (margem Â±1) com delta = 94.9 m
TalhÃ£o: 6443006-01 | n_req: 16 | delta_inicial: 186.16 m | INT_amostral: 5 | Ãrea: 77.15 ha
TalhÃ£o 6443006-01: nÃ£o Ã© possÃ­vel encaixar 16 parcelas com distÃ¢ncia em [200, 186.2] m
TalhÃ£o 6443006-01: aceitando 15 pontos (margem Â±1) com delta = 186.2 m
TalhÃ£o: 6443010-01 | n_req: 12 | delta_inicial: 181.81 m | INT_amostral: 5 | Ãrea: 56.37 ha
TalhÃ£o 6443010-01: nÃ£o Ã© possÃ­vel encaixar 12 parcelas com distÃ¢ncia em [200, 181.8] m
TalhÃ£o 6443010-01: impossÃ­vel alocar 12 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6443007-01 | n_req: 20 | delta_inicial: 195.63 m | INT_amostral: 5 | Ãrea: 99.44 ha
TalhÃ£o 6443007-01: nÃ£o Ã© possÃ­vel encaixar 20 parcelas com distÃ¢ncia em [200, 195.6] m
TalhÃ£o 6443007-01: aceitando 19 pontos (margem Â±1) com delta = 195.6 m
TalhÃ£o: 6356006-01 | n_req: 17 | delta_inicial: 190.8 m | INT_amostral: 5 | Ãrea: 84.61 ha
TalhÃ£o 6356006-01: nÃ£o Ã© possÃ­vel encaixar 17 parcelas com distÃ¢ncia em [200, 190.8] m
TalhÃ£o 6356006-01: aceitando 18 pontos (margem Â±1) com delta = 190.8 m
TalhÃ£o: 6449009-01 | n_req: 8 | delta_inicial: 152.61 m | INT_amostral: 5 | Ãrea: 35.13 ha
TalhÃ£o 6449009-01: nÃ£o Ã© possÃ­vel encaixar 8 parcelas com distÃ¢ncia em [200, 152.6] m
TalhÃ£o 6449009-01: aceitando 7 pontos (margem Â±1) com delta = 152.6 m
TalhÃ£o: 6443013-01 | n_req: 15 | delta_inicial: 187.82 m | INT_amostral: 5 | Ãrea: 72.46 ha
TalhÃ£o: 6291010-01 | n_req: 17 | delta_inicial: 183.69 m | INT_amostral: 5 | Ãrea: 83.51 ha
TalhÃ£o: 6443002-01 | n_req: 20 | delta_inicial: 186.17 m | INT_amostral: 5 | Ãrea: 96.84 ha
TalhÃ£o: 6428006-01 | n_req: 2 | delta_inicial: 10.73 m | INT_amostral: 5 | Ãrea: 3.57 ha
Aviso em min(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
TalhÃ£o 6428006-01: nÃ£o Ã© possÃ­vel encaixar 2 parcelas com distÃ¢ncia em [200, 10.7] m
TalhÃ£o 6428006-01: aceitando 1 pontos (margem Â±1) com delta = 10.7 m
TalhÃ£o: 6505028-01 | n_req: 18 | delta_inicial: 186.56 m | INT_amostral: 5 | Ãrea: 86.61 ha
TalhÃ£o 6505028-01: nÃ£o Ã© possÃ­vel encaixar 18 parcelas com distÃ¢ncia em [200, 186.6] m
TalhÃ£o 6505028-01: aceitando 19 pontos (margem Â±1) com delta = 186.6 m
TalhÃ£o: 6505026-01 | n_req: 11 | delta_inicial: 175.68 m | INT_amostral: 5 | Ãrea: 54.65 ha
TalhÃ£o: 6505029-01 | n_req: 13 | delta_inicial: 179.01 m | INT_amostral: 5 | Ãrea: 62.25 ha
TalhÃ£o 6505029-01: nÃ£o Ã© possÃ­vel encaixar 13 parcelas com distÃ¢ncia em [200, 179] m
TalhÃ£o 6505029-01: impossÃ­vel alocar 13 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6268029-01 | n_req: 11 | delta_inicial: 173.25 m | INT_amostral: 5 | Ãrea: 52.37 ha
TalhÃ£o 6268029-01: nÃ£o Ã© possÃ­vel encaixar 11 parcelas com distÃ¢ncia em [200, 173.3] m
TalhÃ£o 6268029-01: impossÃ­vel alocar 11 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6268026-01 | n_req: 9 | delta_inicial: 174.79 m | INT_amostral: 5 | Ãrea: 43.79 ha
TalhÃ£o 6268026-01: nÃ£o Ã© possÃ­vel encaixar 9 parcelas com distÃ¢ncia em [200, 174.8] m
TalhÃ£o 6268026-01: aceitando 8 pontos (margem Â±1) com delta = 174.8 m
TalhÃ£o: 6268034-01 | n_req: 2 | delta_inicial: 16.1 m | INT_amostral: 5 | Ãrea: 3.37 ha
Aviso em min(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em min(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para min; retornando Inf
Aviso em max(cc[[1]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
Aviso em max(cc[[2]], na.rm = TRUE) :
  nenhum argumento não faltante para max; retornando -Inf
TalhÃ£o 6268034-01: nÃ£o Ã© possÃ­vel encaixar 2 parcelas com distÃ¢ncia em [200, 16.1] m
TalhÃ£o 6268034-01: aceitando 1 pontos (margem Â±1) com delta = 16.1 m
TalhÃ£o: 6319009-01 | n_req: 11 | delta_inicial: 151.99 m | INT_amostral: 5 | Ãrea: 53.09 ha
TalhÃ£o 6319009-01: nÃ£o Ã© possÃ­vel encaixar 11 parcelas com distÃ¢ncia em [200, 152] m
TalhÃ£o 6319009-01: impossÃ­vel alocar 11 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6356003-01 | n_req: 14 | delta_inicial: 186.22 m | INT_amostral: 5 | Ãrea: 69.16 ha
TalhÃ£o 6356003-01: nÃ£o Ã© possÃ­vel encaixar 14 parcelas com distÃ¢ncia em [200, 186.2] m
TalhÃ£o 6356003-01: aceitando 15 pontos (margem Â±1) com delta = 186.2 m
TalhÃ£o: 6443008-01 | n_req: 15 | delta_inicial: 183.24 m | INT_amostral: 5 | Ãrea: 70.44 ha
TalhÃ£o: 6443012-01 | n_req: 5 | delta_inicial: 160.99 m | INT_amostral: 5 | Ãrea: 24.81 ha
TalhÃ£o 6443012-01: nÃ£o Ã© possÃ­vel encaixar 5 parcelas com distÃ¢ncia em [200, 161] m
TalhÃ£o 6443012-01: impossÃ­vel alocar 5 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6443015-01 | n_req: 17 | delta_inicial: 193.74 m | INT_amostral: 5 | Ãrea: 84.59 ha
TalhÃ£o 6443015-01: nÃ£o Ã© possÃ­vel encaixar 17 parcelas com distÃ¢ncia em [200, 193.7] m
TalhÃ£o 6443015-01: aceitando 16 pontos (margem Â±1) com delta = 200 m
TalhÃ£o: 6387008-01 | n_req: 14 | delta_inicial: 183.93 m | INT_amostral: 5 | Ãrea: 68.88 ha
TalhÃ£o 6387008-01: nÃ£o Ã© possÃ­vel encaixar 14 parcelas com distÃ¢ncia em [200, 183.9] m
TalhÃ£o 6387008-01: aceitando 13 pontos (margem Â±1) com delta = 183.9 m
TalhÃ£o: 6475004-01 | n_req: 13 | delta_inicial: 171.57 m | INT_amostral: 5 | Ãrea: 62.38 ha
TalhÃ£o 6475004-01: nÃ£o Ã© possÃ­vel encaixar 13 parcelas com distÃ¢ncia em [200, 171.6] m
TalhÃ£o 6475004-01: impossÃ­vel alocar 13 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6518017-01 | n_req: 21 | delta_inicial: 169.96 m | INT_amostral: 5 | Ãrea: 101.32 ha
TalhÃ£o 6518017-01: nÃ£o Ã© possÃ­vel encaixar 21 parcelas com distÃ¢ncia em [200, 170] m
TalhÃ£o 6518017-01: impossÃ­vel alocar 21 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6431011-01 | n_req: 13 | delta_inicial: 176.31 m | INT_amostral: 5 | Ãrea: 61.07 ha
TalhÃ£o 6431011-01: nÃ£o Ã© possÃ­vel encaixar 13 parcelas com distÃ¢ncia em [200, 176.3] m
TalhÃ£o 6431011-01: impossÃ­vel alocar 13 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6449001-01 | n_req: 11 | delta_inicial: 105.53 m | INT_amostral: 5 | Ãrea: 52.02 ha
TalhÃ£o 6449001-01: nÃ£o Ã© possÃ­vel encaixar 11 parcelas com distÃ¢ncia em [200, 105.5] m
TalhÃ£o 6449001-01: aceitando 10 pontos (margem Â±1) com delta = 105.5 m
TalhÃ£o: 6431012-01 | n_req: 13 | delta_inicial: 185.12 m | INT_amostral: 5 | Ãrea: 62.07 ha
TalhÃ£o: 6268028-01 | n_req: 15 | delta_inicial: 173.57 m | INT_amostral: 5 | Ãrea: 74.94 ha
TalhÃ£o 6268028-01: nÃ£o Ã© possÃ­vel encaixar 15 parcelas com distÃ¢ncia em [200, 173.6] m
TalhÃ£o 6268028-01: aceitando 14 pontos (margem Â±1) com delta = 173.6 m
TalhÃ£o: 6459015-01 | n_req: 14 | delta_inicial: 169.48 m | INT_amostral: 5 | Ãrea: 66.1 ha
TalhÃ£o 6459015-01: nÃ£o Ã© possÃ­vel encaixar 14 parcelas com distÃ¢ncia em [200, 169.5] m
TalhÃ£o 6459015-01: aceitando 13 pontos (margem Â±1) com delta = 169.5 m
TalhÃ£o: 6443011-01 | n_req: 7 | delta_inicial: 156.2 m | INT_amostral: 5 | Ãrea: 33.01 ha
TalhÃ£o 6443011-01: nÃ£o Ã© possÃ­vel encaixar 7 parcelas com distÃ¢ncia em [200, 156.2] m
TalhÃ£o 6443011-01: impossÃ­vel alocar 7 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6436062-01 | n_req: 7 | delta_inicial: 147.29 m | INT_amostral: 5 | Ãrea: 33.06 ha
TalhÃ£o: 6431048-01 | n_req: 19 | delta_inicial: 184.8 m | INT_amostral: 5 | Ãrea: 90.51 ha
TalhÃ£o 6431048-01: nÃ£o Ã© possÃ­vel encaixar 19 parcelas com distÃ¢ncia em [200, 184.8] m
TalhÃ£o 6431048-01: impossÃ­vel alocar 19 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6436047-01 | n_req: 15 | delta_inicial: 189.59 m | INT_amostral: 5 | Ãrea: 73.2 ha
TalhÃ£o 6436047-01: nÃ£o Ã© possÃ­vel encaixar 15 parcelas com distÃ¢ncia em [200, 189.6] m
TalhÃ£o 6436047-01: aceitando 14 pontos (margem Â±1) com delta = 200 m
TalhÃ£o: 6518002-01 | n_req: 14 | delta_inicial: 183.31 m | INT_amostral: 5 | Ãrea: 67.68 ha
TalhÃ£o 6518002-01: nÃ£o Ã© possÃ­vel encaixar 14 parcelas com distÃ¢ncia em [200, 183.3] m
TalhÃ£o 6518002-01: impossÃ­vel alocar 14 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6518001-01 | n_req: 20 | delta_inicial: 190.05 m | INT_amostral: 5 | Ãrea: 95.59 ha
TalhÃ£o 6518001-01: nÃ£o Ã© possÃ­vel encaixar 20 parcelas com distÃ¢ncia em [200, 190] m
TalhÃ£o 6518001-01: impossÃ­vel alocar 20 parcelas com distÃ¢ncia â‰¥ 200 m
TalhÃ£o: 6459024-01 | n_req: 12 | delta_inicial: 177.79 m | INT_amostral: 5 | Ãrea: 57.08 ha
TalhÃ£o 6459024-01: nÃ£o Ã© possÃ­vel encaixar 12 parcelas com distÃ¢ncia em [200, 177.8] m
TalhÃ£o 6459024-01: aceitando 11 pontos (margem Â±1) com delta = 177.8 m
TalhÃ£o: 6505035-01 | n_req: 13 | delta_inicial: 169.07 m | INT_amostral: 5 | Ãrea: 61.95 ha
