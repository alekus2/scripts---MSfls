output$download_result <- downloadHandler(
  filename = function() {
    data_str <- format(Sys.time(), "%d-%m-%y_%H.%M")
    paste0("parcelas_", tipo_parcela(), "_", data_str, ".zip")  
  },
  content = function(file) {
    req(values$result_points)
    temp_dir <- tempdir()
    shapefile_dir <- file.path(temp_dir, "parcelas")
    dir.create(shapefile_dir, showWarnings = FALSE)
    
    # caminho completo do shapefile .shp
    shapefile_path <- file.path(
      shapefile_dir,
      paste0("parcelas_", tipo_parcela(), "_", format(Sys.time(), "%d-%m-%y_%H.%M"), ".shp")
    )
    
    # escreve todos os arquivos do shapefile
    st_write(values$result_points, dsn = shapefile_path,
             driver = "ESRI Shapefile", delete_dsn = TRUE)
    
    # lista *TODOS* os componentes do shapefile
    shapefile_files <- list.files(
      path = shapefile_dir,
      pattern = "\\.(shp|shx|dbf|prj|cpg|qpj)$",
      full.names = TRUE
    )
    
    # comprime
    zip::zipr(zipfile = file, files = shapefile_files,
              root = shapefile_dir)
  },
  contentType = "application/zip"
)
