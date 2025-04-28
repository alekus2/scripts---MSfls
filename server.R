library(shiny)
library(sf)
library(DBI)
library(odbc)
library(stringr)
library(dplyr)
library(ggplot2)
library(zip)

server <- function(input, output, session) {
  
  # 1) conexao ArcSDE Oracle
  observeEvent(input$db_connect, {
    req(input$db_host, input$db_port, input$db_service,
        input$db_user, input$db_pwd)
    con <- dbConnect(odbc(),
                     Driver   = "Oracle",       # ajuste conforme seu driver
                     Server   = input$db_host,
                     UID      = input$db_user,
                     PWD      = input$db_pwd,
                     Port     = input$db_port,
                     SVC      = input$db_service)
    # lista apenas tabelas contendo "talhao"
    tbls <- dbListTables(con)
    tl <- grep("talhao", tbls, ignore.case = TRUE, value = TRUE)
    updateSelectInput(session, "db_table",
                      choices = tl,
                      selected = tl[1])
    session$userData$db_con <- con
  })
  
  output$db_layer_selector <- renderUI({
    req(input$data_source == "db")
    selectInput("db_table", "Escolha camada de talhões:", choices = NULL)
  })
  
  # 2) textos de confirmação
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
    output$recomend_text <- renderText({
      req(input$recomend)
      paste("Upload de recomendação:", input$recomend$name)
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
      req(input$forma_parcela, input$tipo_parcela, input$distancia_minima)
      paste("Forma:", input$forma_parcela,
            "| Tipo:", input$tipo_parcela,
            "| Distância mínima:", input$distancia_minima)
    })
  })
  
  # 3) shape() unificado: upload ZIP ou DB ArcSDE
  shape <- reactive({
    if (input$data_source == "upload") {
      req(input$shape)
      zp <- unzip(input$shape$datapath, exdir = tempdir())
      shpfile <- grep("\\.shp$", zp, value = TRUE)
      shp <- st_read(shpfile, quiet = TRUE)
    } else {
      # via driver OCI do GDAL
      con <- session$userData$db_con
      req(con, input$db_table)
      dsn <- sprintf("OCI:%s/%s@%s:%s/%s",
                     input$db_user, input$db_pwd,
                     input$db_host, input$db_port,
                     input$db_service)
      shp <- st_read(dsn = dsn, layer = input$db_table, quiet = TRUE)
    }
    # renomeia e padroniza se for o formato “Outro”
    if (input$shape_input_pergunta_arudek == 0) {
      shp <- shp %>%
        rename(
          ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
          TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
          CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
          ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
        )
    }
    shp %>%
      mutate(
        ID_PROJETO = str_pad(ID_PROJETO, 4, pad = "0"),
        TALHAO     = str_pad(TALHAO,     3, pad = "0")
      )
  })
  
  # 4) restante do server: recomend(), gerar_parcelas, plot, download…
  # — você mantém aqui todo o código que já tinha, substituindo as referências a shape_path() por shape()
  # — e garantindo que calls a shape() continuem funcionando igual.
  # (Por brevidade não reproduzi tudo de novo, mas basta colar o seu código antigo
  #  a partir de recomend() até o downloadHandler, usando este shape().)
  
}

shinyApp(ui = ui, server = server)

# Se separar em arquivos, salve como app_server.R
