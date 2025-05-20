process_data <- function(shape_full, intensidade, buffer, dist_min) {
  shape_full <- st_make_valid(shape_full)

  shape_full <- shape_full |>
    mutate(area_ha = as.numeric(st_area(geometry)) / 10000) |>
    filter(area_ha >= 0.1) |>
    mutate(n_parcelas = round(area_ha * intensidade))

  grid_all <- st_sf()
  for (i in seq_len(nrow(shape_full))) {
    shp <- shape_full[i, ]
    env <- st_bbox(st_buffer(st_geometry(shp), -buffer))
    dist <- dist_min
    x_seq <- seq(env["xmin"], env["xmax"], by = dist)
    y_seq <- seq(env["ymin"], env["ymax"], by = dist)
    cc <- expand.grid(x_seq, y_seq)

    if (nrow(cc) == 0) next

    pts <- st_as_sf(cc, coords = c("Var1", "Var2"), crs = st_crs(shape_full))
    pts_in <- pts[shp, op = st_within]

    if (nrow(pts_in) == 0) next

    n_req <- shp$n_parcelas
    if (nrow(pts_in) >= n_req) {
      coords <- st_coordinates(pts_in)
      centroid <- st_centroid(st_geometry(shp))
      if (!inherits(centroid, "sfc")) {
        centroid <- st_sfc(centroid, crs = st_crs(shape_full))
      }
      centroide_coords <- st_coordinates(centroid)
      dists <- sqrt((coords[,1] - centroide_coords[1])^2 + (coords[,2] - centroide_coords[2])^2)
      ord <- order(dists)
      sel <- pts_in[ord][1:n_req]

      # Garante que sel seja sfc
      if (!inherits(sel$geometry, "sfc")) {
        sel$geometry <- st_sfc(sel$geometry, crs = st_crs(shape_full))
      }

      sel <- sel |>
        mutate(
          TALHAO = shp$TALHAO,
          area_ha = shp$area_ha,
          n_parcelas = shp$n_parcelas,
          COORD_X = st_coordinates(.)[, 1],
          COORD_Y = st_coordinates(.)[, 2]
        )

      grid_all <- rbind(grid_all, sel)
    } else {
      need <- n_req - nrow(pts_in)
      centroid <- st_centroid(st_geometry(shp))
      if (!inherits(centroid, "sfc")) {
        centroid <- st_sfc(centroid, crs = st_crs(shape_full))
      }
      coords_pt <- st_coordinates(centroid)

      extras <- st_sf(
        TALHAO     = rep(shp$TALHAO, need),
        area_ha    = rep(shp$area_ha, need),
        n_parcelas = rep(shp$n_parcelas, need),
        COORD_X    = rep(coords_pt[1], need),
        COORD_Y    = rep(coords_pt[2], need),
        geometry   = st_sfc(rep(centroid[[1]], need), crs = st_crs(shape_full))
      )

      pts_in <- pts_in |>
        mutate(
          TALHAO = shp$TALHAO,
          area_ha = shp$area_ha,
          n_parcelas = shp$n_parcelas,
          COORD_X = st_coordinates(.)[, 1],
          COORD_Y = st_coordinates(.)[, 2]
        )

      grid_all <- rbind(grid_all, pts_in, extras)
    }
  }

  grid_all <- grid_all |>
    group_by(TALHAO) |>
    mutate(NM_PARCELA = paste0("P", stringr::str_pad(row_number(), 3, "left", "0"))) |>
    ungroup()

  return(grid_all)
}
