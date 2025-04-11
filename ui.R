
library(shiny)
library(shinythemes)

bracell_primary <- "#003366"
bracell_secondary <- "#0077C8"
bracell_white <- "#FFFFFF"

ui <- tagList(
  tags$head(
    tags$style(HTML(paste0("
      body {
        background-color: ", bracell_white, ";
        font-family: 'Segoe UI', sans-serif;
      }
      .navbar {
        background-color: ", bracell_primary, " !important;
        margin-bottom: 0px;
        border: none;
        border-radius: 0;
      }
      .navbar-default .navbar-brand,
      .navbar-default .navbar-nav > li > a {
        color: ", bracell_white, " !important;
      }
      .tab-content {
        padding: 20px;
        background-color: #f4f4f4;
        border-top: 2px solid ", bracell_secondary, ";
      }
      #logo {
        position: fixed;
        top: 10px;
        right: 20px;
        width: 100px;
        height: auto;
        z-index: 9999;
      }
      .btn {
        background-color: ", bracell_secondary, ";
        color: white;
        border: none;
        font-weight: bold;
      }
      .btn:hover {
        background-color: ", bracell_primary, ";
      }
      .sobre-texto {
        font-size: 16px;
        color: #000;
        text-align: justify;
      }
      .sobre-texto h2 {
        font-size: 24px;
        color: ", bracell_primary, ";
      }
    ")))
  ),
  tags$img(src = "logo.png", id = "logo"),
  
  navbarPage("AUTOALOCAR    -    Alocador de Parcelas", theme = shinytheme("flatly"),
             
    tabPanel("Sobre", icon = icon("info"),
      fluidRow(
        column(12,
          div(class = "sobre-texto",
            h2("Sobre"),
            p("Ferramenta desenvolvida em Shiny (R) para o lanÃ§amento de parcelas com grid da organizaÃ§Ã£o, que integra informaÃ§Ãµes de recomendaÃ§Ã£o, shapefile dos talhÃµes e parcelas histÃ³ricas."),
            HTML("<b style='color:red;'>O aplicativo foi desenvolvido para facilitar o processo de lanÃ§amento. No entanto, sua utilizaÃ§Ã£o nÃ£o elimina a necessidade de anÃ¡lises criteriosas!</b>")
          )
        )
      )
    ),

    tabPanel("Dados", icon = icon("file-upload"),
      sidebarLayout(
        sidebarPanel(
          fileInput("shape", "Upload do Shapefile dos talhÃµes", accept = c(".zip")),
          fileInput("grid_existente", "Carregar Grid Existente (.shp):", multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj')),
          radioButtons("shape_input_pergunta_arudek", "Formato do shape de entrada?",
                       choices = list("ARUDEK.VW_GIS_POL_USO_SOLO" = 1, "Outro" = 0), selected = 1),
          conditionalPanel("input.shape_input_pergunta_arudek == 0",
            textInput("mudar_nome_arudek_projeto", "Projeto:", "ID_PROJETO"),
            textInput("mudar_nome_arudek_talhao", "TalhÃ£o:", "CD_TALHAO"),
            textInput("mudar_nome_arudek_ciclo", "Ciclo:", "NUM_CICLO"),
            textInput("mudar_nome_arudek_rotacao", "RotaÃ§Ã£o:", "NUM_ROTAC")
          ),
          radioButtons("recomendacao_pergunta_upload", "Deseja realizar o upload do arquivo de recomendaÃ§Ã£o?",
                       choices = list("Sim" = 1, "NÃO" = 0), selected = 1),
          conditionalPanel("input.recomendacao_pergunta_upload == 1",
            fileInput("recomend", "Upload do arquivo de recomendaÃ§Ã£o", accept = c(".csv"))
          ),
          conditionalPanel("input.recomendacao_pergunta_upload == 0",
            numericInput("recomend_intensidade", "Intensidade por parcela (ha):", value = 3)
          ),
          radioButtons("parcelas_existentes_lancar", "Deseja informar as parcelas jÃ¡ existentes?",
                       choices = list("Sim" = 1, "NÃO" = 0), selected = 0),
          conditionalPanel("input.parcelas_existentes_lancar == 1",
            fileInput("parc_exist", "Upload do Shapefile das parcelas jÃ¡ existentes", accept = c(".zip"))
          ),
          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC")),
          conditionalPanel("input.tipo_parcela == 'IPC'",
            radioButtons("lancar_sobrevivencia", "LanÃ§ar parcelas de sobrevivÃªncia?", choices = list("Sim" = 1, "NÃO" = 0), selected = 0)
          ),
          sliderInput("distancia_minima", "DistÃ¢ncia MÃ­nima:", min = 5, max = 25, value = 20, step = 0.5),
          actionButton("confirmar", "Confirmar")
        ),
        mainPanel(
          div(class = "sobre-texto",
            h2("Sobre os arquivos"),
            p("Shape dos talhÃµes: .zip com todos os arquivos do shapefile."),
            p("RecomendaÃ§Ã£o: planilha .csv com colunas Projeto, Talhao e N."),
            p("Parcelas histÃ³ricas: .zip com os shapefiles das parcelas existentes.")
          ),
          verbatimTextOutput("shape_text"),
          verbatimTextOutput("recomend_text"),
          verbatimTextOutput("parc_exist_text"),
          verbatimTextOutput("confirmation"),
          conditionalPanel("input.recomendacao_pergunta_upload == 0",
            textInput("download_recomend_name", "Nome do arquivo de recomendaÃ§Ã£o:", "RecomendaÃ§Ã£o-"),
            downloadButton("download_recomend", "Download da RecomendaÃ§Ã£o criada*"),
            p("*DisponÃ­vel apÃ³s o upload das demais informaÃ§Ãµes")
          )
        )
      )
    ),

    tabPanel("Parcelas Plotadas", icon = icon("chart-bar"),
      tabsetPanel(
        tabPanel("Status", icon = icon("clock"),
          sidebarLayout(
            sidebarPanel(
              h2("Gerar parcelas", style = paste0("color:", bracell_primary, ";")),
              p("Clique no botÃ£o abaixo para gerar as parcelas."),
              actionButton("gerar_parcelas", "Gerar Parcelas")
            ),
            mainPanel(
              div(id = "progress-container", style = "width: 100%; background-color: #f3f3f3; padding: 3px;",
                  div(id = "progress-bar", style = "width: 0%; height: 20px; background-color: #4CAF50; text-align: center; line-height: 20px; color: white;")
              ),
              div(id = "completed-message", style = "display: none; font-weight: bold; color: green;", "ConcluÃ­do")
            )
          )
        ),
        tabPanel("PARCELAS PLOTADAS", icon = icon("map"),
          fluidPage(
            br(),
            fluidRow(
              column(2, offset = 1, actionButton("anterior", "ANTERIOR", class = "btn")),
              column(2, actionButton("proximo", "PRÃXIMO", class = "btn")),
              column(5, actionButton("gerar_parcelas", "GERAR NOVAMENTE AS PARCELAS", class = "btn btn-danger"))
            ),
            br(), br(),
            fluidRow(
              column(10, offset = 1,
                     div(style = "color:red; font-weight:bold; font-size:16px; text-align:justify;",
                         "O nÃºmero de parcelas alocadas pode diferir do nÃºmero recomendado. Avalie no ArcGIS Pro!")
              )
            )
          )
        ),
        tabPanel("DOWNLOAD",
          fluidPage(
            br(),
            wellPanel(
              h4("Download"),
              p("Arquivo gerado com base nas especificaÃ§Ãµes."),
              textInput("nome_arquivo", "Nome do arquivo:", value = paste0("Parcelas_", Sys.Date())),
              downloadButton("download_result", "DOWNLOAD PARCELAS", class = "btn btn-dark"),
              br(), br(),
              div(style = "color:red; font-weight:bold;",
                  "Nota: Altere o nome para cada arquivo salvo.")
            )
          )
        )
      )
    )
  ),

  tags$script(HTML("
    Shiny.addCustomMessageHandler('update_progress', function(percent) {
      $('#progress-bar').css('width', percent + '%');
      $('#progress-bar').text(percent + '%');
    });
    Shiny.addCustomMessageHandler('show_completed', function(message) {
      $('#completed-message').show();
    });
    Shiny.addCustomMessageHandler('hide_completed', function(message) {
      $('#completed-message').hide();
    });
  "))
)
