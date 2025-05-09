library(shiny)
library(shinythemes)

bracell_primary   <- "#007E69"
bracell_secondary <- "#5f8b27"
bracell_white     <- "#FFFFFF"

ui <- fluidPage(
  tags$head(
    tags$style(HTML(paste0("
      body {
        background-color: ", bracell_white, ";
        font-family: 'Segoe UI', sans-serif;
      }
      shiny-notification {
        position: fixed;
        top: 10px;
        right: 10px;
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
      .navbar-nav > li.active > a {
        color: ", bracell_secondary, " !important;
      }
      .tab-content {
        padding: 20px;
        background-color: #f4f4f4;
        border-top: 2px solid ", bracell_secondary, ";
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
      .btn:focus {
        background-color: ", bracell_primary, ";
        outline: none;
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
      .navbar-brand {
        display: flex !important;
        align-items: center !important;
      }
      .navbar-brand img {
        max-height: 40px;
        margin-right: 10px;
      }
    ")))
  ),
  
  navbarPage(
    title = div(tags$img(src = "logo.png", height = "40px"), "ALOCADOR DE PARCELAS"),
    
    tabPanel("Dados", icon = icon("file-upload"),
      sidebarLayout(
        sidebarPanel(
          radioButtons("data_source", "Fonte dos talhões:",
                       choices = c("Upload shapefile (.zip)" = "upload"),
                       selected = "upload"),
          conditionalPanel(
            "input.data_source == 'upload'",
            fileInput("shape", "Upload do Shapefile dos talhões (.zip)", accept = c(".zip"))
          ),
          radioButtons("shape_input_pergunta_arudek", label = h3("Qual o formato do shape de entrada?"),
                       choices = list("P_SDE_BRACELL_PUB...ETC" = 1, "Outro" = 0), selected = 1),
          conditionalPanel("input.shape_input_pergunta_arudek == 0",
            textInput("mudar_nome_arudek_projeto", "Projeto:", "ID_PROJETO"),
            textInput("mudar_nome_arudek_talhao",   "Talhão:",  "CD_TALHAO"),
            textInput("mudar_nome_arudek_ciclo",    "Ciclo:",   "CICLO"),
            textInput("mudar_nome_arudek_rotacao",  "Rotação:", "ROTACAO")
          ),
          numericInput("intensidade_amostral", "Intensidade amostral (parcelas/ha):", value = 5),
          selectizeInput("forma_parcela", "Forma da parcela:", choices = c("CIRCULAR", "RETANGULAR")),
          selectizeInput("tipo_parcela",  "Tipo da parcela:",   choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC")),
          conditionalPanel(
            "input.tipo_parcela == 'IPC'",
            radioButtons("lancar_sobrevivencia", "Lançar parcelas de sobrevivência?",
                         choices = list("Sim" = 1, "Não" = 0), selected = 0)
          ),
          sliderInput("distancia_minima", "Distância mínima (m):", min = 30, max = 100, value = 50, step = 10),
          actionButton("confirmar", "Confirmar", class = "btn btn-danger")
        ),
        mainPanel(
          div(class = "sobre-texto",
              h2("Sobre os arquivos"),
              br(),
              div(tags$b("Shape dos talhões:"), " .zip contendo os arquivos do shapefile."),
              div(tags$b("Parcelas existentes:"), " .zip com o shapefile das parcelas existentes."),
              br(),
              p(style="color:red;
                   font-size:16px;
                   font-weight:bold",
                "Lembre sempre de conferir a distancia entre as parcelas, a Distância Miníma pode alterar a quantidade de parcelas a serem alocadas!")
          ),
          br(),
          div(class="sobre-texto",
              h2("Como plotar?"),
              br(),
              p(style = "color:black;font-weight:semi-bold",
                "Altere os dados que deseja, clique em 'Confirmar'. Em seguida vá na aba 'Plotagem' e clique em 'Gerar Parcelas'.")
          ),
          verbatimTextOutput("shape_text"),
          verbatimTextOutput("parc_exist_text"),
          verbatimTextOutput("confirmation")
        )
      )
    ),
    
    tabPanel("Plotagem", icon = icon("chart-bar"),
      tabsetPanel(
        tabPanel("Status", icon = icon("clock"),
          sidebarLayout(
            sidebarPanel(
              h2("Gerar parcelas", style = paste0("color:", bracell_primary, ";")),
              actionButton("gerar_parcelas", "Gerar Parcelas", class = "btn btn-danger")
            ),
            mainPanel(class = "main-panel",
              div(id = "progress-container", style = "width:100%; background-color:#f3f3f3; padding:3px;",
                  div(id = "progress-bar", style = "width:0%; height:20px; text-align:center; line-height:20px; color:white;")
              ),
              div(id = "completed-message", style = "display:none; font-weight:bold; color:green;", "Concluído")
            )
          )
        ),
        tabPanel("Mapa das Parcelas", icon = icon("chart-bar"),
          fluidPage(
            fluidRow(
              column(3, uiOutput("index_filter")),
              column(10, plotOutput("plot", height = "400px"))
            ),
            br(),
            fluidRow(
              column(2, actionButton("anterior", "ANTERIOR", class = "btn btn-danger")),
              column(2, actionButton("proximo",   "PRÓXIMO",   class = "btn btn-danger")),
              column(3, actionButton("gerar_novamente", "GERAR NOVAMENTE AS PARCELAS", class = "btn btn-danger"))
            ),
            br(),
            fluidRow(
              column(10, offset = 1,
                     div(style = "color:red; font-weight:bold; font-size:16px; text-align:justify;",
                         "O número de parcelas alocadas pode diferir do número recomendado. Avalie no ArcGIS Pro!"
                     )
              )
            )
          )
        ),
        tabPanel("Download", icon = icon("download"),
          fluidPage(
            wellPanel(
              h4("Download"),
              p("Arquivo gerado com base nas especificações."),
              downloadButton("download_result", "Download Parcelas", class = "btn btn-danger"),
              div(style = "color:red; font-weight:bold;",
                  "O nome do arquivo será gerado automaticamente com data, hora e tipo de parcela."
              )
            )
          )
        )
      )
    ),
    
    tabPanel("Sobre", icon = icon("info"),
      fluidRow(
        column(12,
          div(class = "sobre-texto",
              h2("Sobre"),
              p("Ferramenta desenvolvida em Shiny (R) para o lançamento de parcelas com grid da organização, que integra informações de shapefile dos talhões e processamento por intensidade amostral."),
              div(tags$b("Atenção:"),style= "color:red"," Este app facilita o processo, mas não substitui análises criteriosas no ArcGIS Pro.")
          )
        )
      )
    )
    
  ),  # fecha o navbarPage()
  
  tags$script(HTML("
    Shiny.addCustomMessageHandler('update_progress', function(percent) {
      $('#progress-bar').css('width', percent + '%').text(percent + '%');
    });
    Shiny.addCustomMessageHandler('show_completed', function(message) {
      $('#completed-message').show();
    });
    Shiny.addCustomMessageHandler('hide_completed', function(message) {
      $('#completed-message').hide();
    });
    $(document).on('click', '.navbar-nav > li', function() {
      $('.navbar-nav > li').removeClass('active');
      $(this).addClass('active');
    });
  "))
)

shinyApp(ui = ui, server = function(input, output) { })
