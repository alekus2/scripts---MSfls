library(shiny)
library(sf)
library(DBI)
library(odbc)
library(stringr)
library(dplyr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {

  observeEvent(input$db_connect, {
    req(input$db_host, input$db_port, input$db_service, input$db_user, input$db_pwd)
    con <- dbConnect(odbc(),
                     Driver = "Oracle",
                     Server = input$db_host,
                     UID    = input$db_user,
                     PWD    = input$db_pwd,
                     Port   = input$db_port,
                     SVC    = input$db_service)
    tbls <- dbListTables(con)
    tl   <- grep("talhao", tbls, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table", choices = tl, selected = tl[1])
    session$userData$db_con <- con
  })

  output$db_layer_selector <- renderUI({
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })

  observeEvent(input$confirmar, {
    output$shape_text <- renderText({
      if (input$data_source == "upload") {
        req(input$shape)
        paste("Upload realizado shapefile:", input$shape$name)
      } else {
        req(input$db_table)
        paste("Conectado à camada:", input$db_table)
      }
    })
    output$parc_exist_text <- renderText({
      if (input$parcelas_existentes_lancar == 1) {
        req(input$parc_exist)
        paste("Upload parcelas históricas:", input$parc_exist$name)
      } else {
        "Parcelas existentes não informadas."
      }
    })
    output$confirmation <- renderText({
      paste("Forma:", input$forma_parcela,
            "| Tipo:", input$tipo_parcela,
            "| Distância mínima:", input$distancia_minima)
    })
  })

  shape <- reactive({
    req(input$data_source)
    if (input$data_source == "upload") {
      req(input$shape)
      tmpdir <- file.path(tempdir(), tools::file_path_sans_ext(basename(input$shape$name)))
      unlink(tmpdir, recursive = TRUE, force = TRUE)
      dir.create(tmpdir, showWarnings = FALSE)
      unzip(input$shape$datapath, exdir = tmpdir)
      shp_files <- list.files(tmpdir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
      req(length(shp_files) >= 1)
      shppath <- shp_files[1]
      shp <- st_read(shppath, quiet = TRUE)
    } else {
      req(session$userData$db_con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      shp <- st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
    }
    validate(need(inherits(shp, "sf") && nrow(shp) > 0, "Erro na leitura do shapefile"))
    if (!is.null(input$shape_input_pergunta_arudek) &&
        input$shape_input_pergunta_arudek == 0) {
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
    }
    shp %>%
      st_transform(31982) %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO,     3, pad = "0"),
        Index      = paste0(ID_PROJETO, TALHAO)
      )
  })

  parc_exist_path <- reactive({
    if (input$parcelas_existentes_lancar == 1) {
      req(input$parc_exist)
      tmpdir2 <- file.path(tempdir(), tools::file_path_sans_ext(basename(input$parc_exist$name)))
      unlink(tmpdir2, recursive = TRUE, force = TRUE)
      dir.create(tmpdir2, showWarnings = FALSE)
      unzip(input$parc_exist$datapath, exdir = tmpdir2)
      shp2 <- list.files(tmpdir2, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
      req(length(shp2) == 1)
      shp2
    } else {
      "data/parc.shp"
    }
  })

  values <- reactiveValues(result_points = NULL)

  observeEvent(input$gerar_parcelas, {
    progress <- Progress$new(session, min = 0, max = 100)
    on.exit(progress$close())
    result <- process_data(
      shape(),
      parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) progress$set(value = p, message = paste0(p, "% concluído"))
    )
    values$result_points <- result
    showNotification("Parcelas geradas com sucesso!", type = "message", duration = 10)
  })

  output$index_filter <- renderUI({
    req(values$result_points)
    selectInput("selected_index", "Selecione o talhão:", choices = unique(values$result_points$Index))
  })

  observeEvent(input$gerar_novamente, {
    req(values$result_points, input$selected_index)
    sel      <- input$selected_index
    new_base <- filter(values$result_points, Index != sel)
    result2  <- process_data(
      shape() %>% filter(Index == sel),
      parc_exist_path(),
      input$forma_parcela, input$tipo_parcela,
      input$distancia_minima, input$intensidade_amostral,
      function(p) NULL
    )
    values$result_points <- bind_rows(new_base, result2)
    showNotification("Parcelas regeneradas com sucesso!", type = "message", duration = 10)
  })

  observeEvent(input$proximo, {
    idxs <- unique(values$result_points$Index)
    ni   <- which(idxs == input$selected_index) + 1
    if (ni > length(idxs)) ni <- 1
    updateSelectInput(session, "selected_index", selected = idxs[ni])
  })

  observeEvent(input$anterior, {
    idxs <- unique(values$result_points$Index)
    pi   <- which(idxs == input$selected_index) - 1
    if (pi < 1) pi <- length(idxs)
    updateSelectInput(session, "selected_index", selected = idxs[pi])
  })

  output$download_result <- downloadHandler(
    filename = function() {
      paste0("parcelas_", input$tipo_parcela, "_", format(Sys.time(), "%d-%m-%y_%H.%M"), ".zip")
    },
    content = function(file) {
      req(values$result_points)
      ts            <- format(Sys.time(), "%d-%m-%y_%H.%M")
      dir_shp       <- file.path(tempdir(), paste0("parcelas_", input$tipo_parcela, "_", ts))
      unlink(dir_shp, recursive = TRUE, force = TRUE)
      dir.create(dir_shp, showWarnings = FALSE)
      shp_base      <- paste0("parcelas_", input$tipo_parcela, "_", ts)
      shp_path      <- file.path(dir_shp, paste0(shp_base, ".shp"))
      st_write(values$result_points, dsn = shp_path, driver = "ESRI Shapefile", delete_dsn = TRUE)
      files_to_zip  <- list.files(dir_shp, pattern = paste0("^", shp_base, "\\.(shp|shx|dbf|prj|cpg|qpj)$"), full.names = TRUE)
      zip::zipr(zipfile = file, files = files_to_zip, root = dir_shp)
    },
    contentType = "application/zip"
  )

  output$plot <- renderPlot({
    req(values$result_points, input$selected_index)
    shp_sel <- shape() %>% filter(Index == input$selected_index)
    req(nrow(shp_sel) > 0)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)
    area_ha <- as.numeric(st_area(shp_sel)) / 10000
    num_rec <- max(2, ceiling(area_ha / as.numeric(input$intensidade_amostral)))
    ggplot() +
      geom_sf(data = shp_sel, fill = NA, color = "#007E69", size = 1) +
      geom_sf(data = pts_sel, size = 2) +
      ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                     " (Área: ", round(area_ha, 2), " ha)")) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  })

}

> runApp('F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/AutoAlocador/AutoParc.R')
Aviso: Navigation containers expect a collection of `bslib::nav_panel()`/`shiny::tabPanel()`s and/or `bslib::nav_menu()`/`shiny::navbarMenu()`s. Consider using `header` or `footer` if you wish to place content above (or below) every panel's contents.

Listening on http://127.0.0.1:3786
Reading layer `parc' from data source `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
Simple feature collection with 6 features and 66 fields
Geometry type: MULTIPOLYGON
Dimension:     XY
Bounding box:  xmin: 256135.4 ymin: 7573138 xmax: 312547.7 ymax: 7670584
Projected CRS: SIRGAS 2000 / UTM zone 22S
  OBJECTID CD_USO_SOL ID_REGIAO       REGIAO ID_PROJETO                       PROJETO TALHAO TIPO_PROPR ID_GRUPO_U      GRUPO_USO_ ID_USO_SOL          USO_SOLO CICLO ROTACAO      REGIME  ESPACAMENT     GENERO                   ESPECIE MATERIAL_G
1        1      48963         4 MS FLORESTAL       6455           BOM RETIRO II - RRP 002-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. urophylla x E. pellita    AEC2475
2        2      52725         4 MS FLORESTAL       6268               PONTAL II - SRP 027-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. grandis x E. urophylla   SUZA0217
3        3      49938         4 MS FLORESTAL       6436          JATOBÁ GLEBA A - NAD 066-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. grandis x E. urophylla     CO1572
4        4      47926         4 MS FLORESTAL       6443 NOSSA SENHORA DE FÁTIMA - ANR 006-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. grandis x E. urophylla       IPB2
5        5      47223         4 MS FLORESTAL       6443 NOSSA SENHORA DE FÁTIMA - ANR 010-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. grandis x E. urophylla     CO1572
6        6      47220         4 MS FLORESTAL       6443 NOSSA SENHORA DE FÁTIMA - ANR 007-01   Terceiro        100 Área cultivável        108 Plantio comercial     1       1 Implantação 3,60 x 2,50 Eucalyptus E. grandis x E. urophylla       IPB2
       SIST_PROPA DATA_PLANT IDADE_PLAN AREA_HA DECLIVIDAD TIPO_SOLO BACIA_HIDR   BIOMA TIPOLOGIA           MUNICIPIO          ESTADO   PAIS CLASSE_SIT         UNIDADE_GE      CHAVE                      TIPO_CONTR PROJETO_EX DCAA_NUMER REGIONAL_C
1 Clone eucalipto 2025-04-10       0.06   34.17       <NA>      <NA> Pardo (MS) Cerrado    Savana  Ribas do Rio Pardo MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6455002-01                  Parceria rural        MS3       <NA>       <NA>
2 Clone eucalipto 2025-04-12       0.05    6.48       <NA>      <NA> Pardo (MS) Cerrado    Savana Santa Rita do Pardo MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6268027-01 Parceria rural (Nova Esperança)        MS3       <NA>       <NA>
3 Clone eucalipto 2025-04-09       0.06    8.70       <NA>      <NA> Pardo (MS) Cerrado    Savana      Nova Andradina MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6436066-01                  Parceria rural        MS3       <NA>       <NA>
4 Clone eucalipto 2025-03-31       0.08   77.15       <NA>      <NA>   Ivinhema Cerrado    Savana        Anaurilândia MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6443006-01                  Parceria rural        MS3       <NA>       <NA>
5 Clone eucalipto 2025-04-11       0.05   56.37       <NA>      <NA>   Ivinhema Cerrado    Savana        Anaurilândia MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6443010-01                  Parceria rural        MS3       <NA>       <NA>
6 Clone eucalipto 2025-04-02       0.08   99.44       <NA>      <NA>   Ivinhema Cerrado    Savana        Anaurilândia MATO GROSSO SUL BRASIL       <NA> MS FLORESTAL (SIL) 6443007-01                  Parceria rural        MS3       <NA>       <NA>
  REGIONAL_S REGIÃO_CL CERTIFICAC TIPO_LICEN PRODUTO   COLETOR_CU DISTANCIA_ DISTANCIA1 DISTANCI_1 PRECIPITAC CICLO_INVE PORC_SAIDA DATA_PLA_1 DATA_INICI DATA_FIM_V DCAA_DATA_ DCAA_DATA1 DATA_PRIME CD_UNIDADE CD_REGIAO CD_PROJETO CD_TALHAO
1       <NA>       CZ2       <NA>       <NA>    <NA> PP9564551125    28.6200     635.56     664.18          0          1          0 01/02/2025 01/11/2024 01/11/2039       <NA>       <NA>       <NA>          1        11       1595    002-01
2       <NA>       CZ3       <NA>       <NA>    <NA> PP9562681125    27.9600     799.79     827.75          0          1          0 12/02/2025 12/11/2024       <NA>       <NA>       <NA>       <NA>          1        11       1434    027-01
3       <NA>       CZ2       <NA>       <NA>    <NA> PP9564361125    16.1175     593.48     609.60          0          1          0 15/04/2025 01/09/2024 01/09/2039       <NA>       <NA>       <NA>          1        11       1576    066-01
4       <NA>       CZ2       <NA>       <NA>    <NA> PP9564431125     0.0000     560.59     560.59          0          1          0 10/04/2025 10/01/2025 10/01/2040       <NA>       <NA>       <NA>          1        11       1583    006-01
5       <NA>       CZ2       <NA>       <NA>    <NA> PP9564431125     0.0000     560.59     560.59          0          1          0 10/04/2025 10/01/2025 10/01/2040       <NA>       <NA>       <NA>          1        11       1583    010-01
6       <NA>       CZ2       <NA>       <NA>    <NA> PP9564431125     0.0000     560.59     560.59          0          1          0 10/04/2025 10/01/2025 10/01/2040       <NA>       <NA>       <NA>          1        11       1583    007-01
    DATA_REG BUFF_DIST ORIG_FID SHAPE_Leng   SHAPE_Area                       geometry      Index
1 2025-03-25       -30   108293 0.02175040 2.342043e-05 MULTIPOLYGON (((256141.8 76... 6455002-01
2 2025-03-25       -30   115351 0.01280840 1.761309e-06 MULTIPOLYGON (((293376.7 76... 6268027-01
3 2025-03-25       -30   126487 0.01078748 4.128822e-06 MULTIPOLYGON (((278088.9 75... 6436066-01
4 2025-03-25       -30   108758 0.03411427 5.754906e-05 MULTIPOLYGON (((311441.6 75... 6443006-01
5 2025-03-25       -30   108887 0.02584657 4.166042e-05 MULTIPOLYGON (((312547.7 75... 6443010-01
6 2025-03-25       -30   108916 0.03597395 7.659250e-05 MULTIPOLYGON (((311834.3 75... 6443007-01
