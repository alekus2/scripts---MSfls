library(shiny)
library(sf)
library(DBI)
library(odbc)
library(stringr)
library(dplyr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {
  message(">> Server iniciado")

  shape <- reactive({
    message(">> [shape] início")
    req(input$data_source)
    message("   data_source =", input$data_source)

    # 1) leitura
    shp <- if (input$data_source == "upload") {
      req(input$shape)
      message("   lendo shapefile do upload…")
      files <- unzip(input$shape$datapath, exdir = tempdir())
      shpfile <- grep("\\.shp$", files, value = TRUE)
      message("   usando .shp:", shpfile)
      out <- st_read(shpfile, quiet = FALSE)
      message("   st_read OK, class=", paste(class(out), collapse=","), 
              ", nrow=", nrow(out))
      out
    } else {
      message("   lendo shapefile do DB…")
      req(session$userData$db_con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      out <- st_read(dsn = dsn, layer = input$db_table, quiet = FALSE)
      message("   st_read DB OK, class=", paste(class(out), collapse=","), 
              ", nrow=", nrow(out))
      out
    }

    # 2) inspeciona colunas e geometria
    message("   colunas:", paste(names(shp), collapse = ", "))
    has_geom <- tryCatch(!is.null(st_geometry(shp)), error = function(e) FALSE)
    message("   tem geometry? ", has_geom)
    if (!has_geom) {
      stop("Shape não trouxe coluna geometry.")
    }

    # 3) renomeação condicional
    if (!is.null(input$shape_input_pergunta_arudek) &&
        input$shape_input_pergunta_arudek == 0) {
      message("   renomeando colunas…")
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
      message("   colunas após rename:", paste(names(shp), collapse = ", "))
    }

    # 4) reprojeção e novos campos
    message("   prestes a reprojetar…")
    shp_t <- tryCatch(
      st_transform(shp, 31982),
      error = function(e) {
        message("   erro em st_transform: ", e$message)
        stop(e)
      }
    )
    message("   reprojetado, nrow=", nrow(shp_t))

    shp_f <- shp_t %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO,     3, pad = "0"),
        Index      = paste0(ID_PROJETO, TALHAO)
      )
    message("   mutate OK, colunas finais:", paste(names(shp_f), collapse = ", "))
    return(shp_f)
  })

> runApp('F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/AutoAlocador/AutoParc.R')
Aviso: Navigation containers expect a collection of `bslib::nav_panel()`/`shiny::tabPanel()`s and/or `bslib::nav_menu()`/`shiny::navbarMenu()`s. Consider using `header` or `footer` if you wish to place content above (or below) every panel's contents.

Listening on http://127.0.0.1:3786
>> Server iniciado
observeEvent: gerar_parcelas iniciado
parc_exist_path(): inicio
parc_exist_path(): usando default data/parc.shp
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
>> [shape] início
   data_source =upload
   lendo shapefile do upload.
   usando .shp:
Aviso: Error in if: argumento tem comprimento zero
  85: st_transform
  84: mutate
  81: observe [src/server.R#105]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp


