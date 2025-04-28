library(shiny)
library(shinythemes)

bracell_primary <- "#007E69"
bracell_secondary <- "#5f8b27"
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
  
  navbarPage(title = div(tags$img(src = "logo.png", height = "40px"), "ALOCADOR DE PARCELAS"),
             
             tabPanel("Sobre", icon = icon("info"),
                      fluidRow(
                        column(12,
                               div(class = "sobre-texto",
                                   h2("Sobre"),
                                   p("Ferramenta desenvolvida em Shiny (R) para o lançamento de parcelas com grid da organização, que integra informações de recomendação, shapefile dos talhões e parcelas históricas."),
                                   HTML("<b style='color:red;'>O aplicativo foi desenvolvido para facilitar o processo de lançamento de parcelas para ArcGIS PRO. No entanto, sua utilizção NÃO elimina a necessidade de análises criteriosas!</b>")
                               )
                        )
                      )
             ),
             
             tabPanel("Dados", icon = icon("file-upload"),
                      sidebarLayout(
                        sidebarPanel(
                          fileInput("shape", "Upload do Shapefile dos talhões", accept = c(".zip")),
                          
                          radioButtons("shape_input_pergunta_arudek", "Formato do shape de entrada?",
                                       choices = list("P_SDE_BRACELL_PUB.VW_GIS_POL_US" = 1, "Outro" = 0), selected = 1),
                          
                          conditionalPanel("input.shape_input_pergunta_arudek == 0",
                                           textInput("mudar_nome_arudek_projeto", "Projeto:", "ID_PROJETO"),
                                           textInput("mudar_nome_arudek_talhao", "Talhão:", "CD_TALHAO"),
                                           textInput("mudar_nome_arudek_ciclo", "Ciclo:", "NUM_CICLO"),
                                           textInput("mudar_nome_arudek_rotacao", "Rotação:", "NUM_ROTAC")
                          ),
                          
                          radioButtons("recomendacao_pergunta_upload", "Deseja realizar o upload do arquivo de recomendação",
                                       choices = list("Sim" = 1, "Não" = 0), selected = 1),
                          conditionalPanel("input.recomendacao_pergunta_upload == 1",
                                           fileInput("recomend", "Upload do arquivo de recomendação", accept = c(".csv"))
                          ),
                          conditionalPanel("input.recomendacao_pergunta_upload == 0",
                                           numericInput("recomend_intensidade", "Número de parcelas desejadas do talhão:", value = 10)
                          ),
                          
                          h2("Insira a intensidade amostral desejada: "),
                          numericInput("intensidade_amostral", "A quantidade de parcelas por área (ha) :", value = 5),
                          
                          radioButtons("parcelas_existentes_lancar", "Deseja informar as parcelas já existentes?",
                                       choices = list("Sim" = 1, "Não" = 0), selected = 0),
                          conditionalPanel("input.parcelas_existentes_lancar == 1",
                                           fileInput("parc_exist", "Upload do Shapefile das parcelas já existentes", accept = c(".zip"))
                          ),
                          
                          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
                          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC")),
                          conditionalPanel("input.tipo_parcela == 'IPC'",
                                           radioButtons("lancar_sobrevivencia", "Lançar parcelas de sobrevivência?", choices = list("Sim" = 1, "Não" = 0), selected = 0)
                          ),
                          sliderInput("distancia_minima", "Distância Mínima:", min = 30, max = 100, value = 50, step = 10),
                          actionButton("confirmar", "Confirmar", class = "btn btn-danger")
                        ),
                        mainPanel(
                          div(class = "sobre-texto",
                              h2("Sobre os arquivos"),
                              p("Shape dos talhões: .zip com todos os arquivos do shapefile."),
                              p("Recomendação: planilha .csv com colunas Projeto, Talhão e N."),
                              p("Parcelas históricas: .zip com os shapefiles das parcelas existentes.")
                          ),
                          verbatimTextOutput("shape_text"),
                          verbatimTextOutput("recomend_text"),
                          verbatimTextOutput("parc_exist_text"),
                          verbatimTextOutput("confirmation"),
                          conditionalPanel("input.recomendacao_pergunta_upload == 0",
                                           textInput("download_recomend_name", "Nome do arquivo de recomendação:", "Recomendação-"),
                                           downloadButton("download_recomend", "Download da Recomendação criada*"),
                                           p("*Disponível após o upload das demais informações")
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
                                     p("Clique no botão abaixo para gerar as parcelas."),
                                     actionButton("gerar_parcelas", "Gerar Parcelas", class = "btn btn-danger")
                                   ),
                                   mainPanel(
                                     div(id = "progress-container", style = "width: 100%; background-color: #f3f3f3; padding: 3px;",
                                         div(id = "progress-bar", style = "width: 0%; height: 20px; background-color: #4CAF50; text-align: center; line-height: 20px; color: white;")
                                     ),
                                     div(id = "completed-message", style = "display: none; font-weight: bold; color: green;", "Concluído")
                                   )
                                 )
                        ),
                        tabPanel("DOWNLOAD",
                                 fluidPage(
                                   br(),
                                   wellPanel(
                                     h4("Download"),
                                     p("Arquivo gerado com base nas especificações."),
                                     downloadButton("download_result", "DOWNLOAD PARCELAS", class = "btn btn-danger"),
                                     br(), br(),
                                     div(style = "color:red; font-weight:bold;",
                                         "O nome do arquivo será gerado automaticamente com data e hora o tipo de parcela que deseja ser gerada.")
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

    // Script para mudar a cor da aba selecionada
    $(document).on('click', '.navbar-nav > li', function() {
      $('.navbar-nav > li').removeClass('active');
      $(this).addClass('active');
    });
  "))
)

shinyApp(ui = ui, server = function(input, output) {})
