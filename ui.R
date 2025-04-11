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
      .navbar-nav > li.active > a {
        color: blue !important; /* Cor azul para a aba ativa */
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
      .file-input-button {
        position: relative;
        overflow: hidden;
        margin: 0;
      }
      .file-input-button input[type='file'] {
        position: absolute;
        top: 0;
        right: 0;
        opacity: 0; /* Torna o input invisível */
        height: 100%;
        width: 100%;
        cursor: pointer; /* Muda o cursor para indicar que é clicável */
      }
    ")))
  ),
  
  navbarPage(title = div(tags$img(src = "logo.png", height = "40px"), "AUTOALOCAR - Alocador de Parcelas"),
             
             tabPanel("Sobre", icon = icon("info"),
                      fluidRow(
                        column(12,
                               div(class = "sobre-texto",
                                   h2("Sobre"),
                                   p("Ferramenta desenvolvida em Shiny (R) para o lançamento de parcelas com grid da organização, que integra informações de recomendação, shapefile dos talhões e parcelas históricas."),
                                   HTML("<b style='color:red;'>O aplicativo foi desenvolvido para facilitar o processo de lançamento de parcelas para ArcGIS PRO. No entanto, sua utilização NÃO elimina a necessidade de análises criteriosas!</b>")
                               )
                        )
                      )
             ),
             
             tabPanel("Dados", icon = icon("file-upload"),
                      sidebarLayout(
                        sidebarPanel(
                          div(class = "file-input-button",
                              actionButton("upload_shape", "Upload do Shapefile dos talhões", class = "btn btn-danger"),
                              fileInput("shape", NULL, accept = c(".zip"), style = "display: none;")
                          ),
                          div(class = "file-input-button",
                              actionButton("upload_grid", "Carregar Grid Existente (.shp):", class = "btn btn-danger"),
                              fileInput("grid_existente", NULL, multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj'), style = "display: none;")
                          ),
                          radioButtons("shape_input_pergunta_arudek", "Formato do shape de entrada?",
                                       choices = list("ARUDEK.VW_GIS_POL_USO_SOLO" = 1, "Outro" = 0), selected = 1),
                          conditionalPanel("input.shape_input_pergunta_arudek == 0",
                                           textInput("mudar_nome_arudek_projeto", "Projeto:", "ID_PROJETO"),
                                           textInput("mudar_nome_arudek_talhao", "Talhão:", "CD_TALHAO"),
                                           textInput("mudar_nome_arudek_ciclo", "Ciclo:", "NUM_CICLO"),
                                           textInput("mudar_nome_arudek_rotacao", "Rotação:", "NUM_ROTAC")
                          ),
                          radioButtons("recomendacao_pergunta_upload", "Deseja realizar o upload do arquivo de recomendação?",
                                       choices = list("Sim" = 1, "Não" = 0), selected = 1),
                          conditionalPanel("input.recomendacao_pergunta_upload == 1",
                                           div(class = "file-input-button",
                                               actionButton("upload_recomend", "Upload do arquivo de recomendação", class = "btn btn-danger"),
                                               fileInput("recomend", NULL, accept = c(".csv"), style = "display: none;")
                                           )
                          ),
                          conditionalPanel("input.recomendacao_pergunta_upload == 0",
                                           numericInput("recomend_intensidade", "Intensidade por parcela (ha):", value = 3)
                          ),
                          radioButtons("parcelas_existentes_lancar", "Deseja informar as parcelas já existentes?",
                                       choices = list("Sim" = 1, "Não" = 0), selected = 0),
                          conditionalPanel("input.parcelas_existentes_lancar == 1",
                                           div(class = "file-input-button",
                                               actionButton("upload_parc_exist", "Upload do Shapefile das parcelas já existentes", class = "btn btn-danger"),
                                               fileInput("parc_exist", NULL, accept = c(".zip"), style = "display: none;")
                                           )
                          ),
                          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
                          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC")),
                          conditionalPanel("input.tipo_parcela == 'IPC'",
                                           radioButtons("lancar_sobrevivencia", "Lançar parcelas de sobrevivência?", choices = list("Sim" = 1, "Não" = 0), selected = 0)
                          ),
                          sliderInput("distancia_minima", "Distância Mínima:", min = 5, max = 25, value = 20, step = 0.5),
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
                        tabPanel("PARCELAS PLOTADAS", icon = icon("map"),
                                 fluidPage(
                                   br(),
                                   fluidRow(
                                     column(2, offset = 1, actionButton("anterior", "ANTERIOR", class = "btn btn-danger")),
                                     column(2, actionButton("proximo", "PRÓXIMO", class = "btn btn-danger")),
                                     column(5, actionButton("gerar_parcelas", "GERAR NOVAMENTE AS PARCELAS", class = "btn btn-danger"))
                                   ),
                                   br(), br(),
                                   fluidRow(
                                     column(10, offset = 1,
                                            div(style = "color:red; font-weight:bold; font-size:16px; text-align:justify;",
                                                "O número de parcelas alocadas pode diferir do número recomendado. Avalie no ArcGIS Pro!")
                                     )
                                   )
                                 )
                        ),
                        tabPanel("DOWNLOAD",
                                 fluidPage(
                                   br(),
                                   wellPanel(
                                     h4("Download"),
                                     p("Arquivo gerado com base nas especificações."),
                                     textInput("nome_arquivo", "Nome do arquivo:", value = paste0("Parcelas_", Sys.Date())),
                                     downloadButton("download_result", "DOWNLOAD PARCELAS", class = "btn btn-danger"),
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

    // Script para mudar a cor da aba selecionada
    $(document).on('click', '.navbar-nav > li', function() {
      $('.navbar-nav > li').removeClass('active');
      $(this).addClass('active');
    });

    // Script para ativar o fileInput ao clicar no botão estilizado
    $(document).on('click', '#upload_shape', function() {
      $('#shape').click();
    });
    $(document).on('click', '#upload_grid', function() {
      $('#grid_existente').click();
    });
    $(document).on('click', '#upload_recomend', function() {
      $('#recomend').click();
    });
    $(document).on('click', '#upload_parc_exist', function() {
      $('#parc_exist').click();
    });
  "))
)

shinyApp(ui = ui, server = function(input, output) {})