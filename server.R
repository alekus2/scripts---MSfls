content = function(file) {
  req(values$result_points)
  data_str <- format(Sys.time(), "%d-%m-%y_%H.%M")
  # pasta única para este download
  shapefile_dir <- tempfile(pattern = paste0("parcelas_", tipo_parcela(), "_", data_str, "_"))
  dir.create(shapefile_dir)
  
  shp_path <- file.path(shapefile_dir,
                        paste0("parcelas_", tipo_parcela(), "_", data_str, ".shp"))
  st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
  
  files <- list.files(shapefile_dir,
                      pattern = "\\.(shp|shx|dbf|prj|cpg|qpj)$",
                      full.names = TRUE)
  zip::zipr(zipfile = file, files = files, root = shapefile_dir)
}
