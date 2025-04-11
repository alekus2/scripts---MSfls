
library(shiny)
library(shinythemes)

ui <- tagList(
  tags$head(
    tags$style(HTML("
      body {
        margin: 0;
        padding: 0;
      }
      .navbar {
        width: 100%;
        margin: 0;
        border-radius: 0;
      }
      #logo {
        position: fixed;
        top: 10px;
        right: 20px;
        width: 100px;
        height: auto;
        z-index: 9999;
      }
      .sobre-texto {
        font-family: 'Arial', sans-serif;
        font-size: 16px;
        line-height: 1.5;
        text-align: justify;
      }
      .sobre-texto h2 {
        font-size: 24px;
        margin-bottom: 16px;
      }
      .sobre-texto p {
        margin-bottom: 16px;
      }
    "))
  ),
  
  tags$img(src = "logo.png", id = "logo"),
  navbarPage("AUTOALOCAR    -    Alocador de Parcelas", theme = shinytheme("sandstone"),
             windowTitle = "Window Title",
             
             tabPanel("Sobre", icon = icon("info"),
                      fluidRow(
                        column(12,
                               div(class = "sobre-texto",
                                   h2("Sobre"),
                                   p("Ferramenta desenvolvida em Shiny (R) para o lançamento de parcelas com grid da organização, que integra informações de recomendação, shapefile dos talhões e parcelas históricas. Essa aplicação permite aos usuários realizar o lançamento de parcelas de maneira automática e depois exportar o shapefile das parcelas."),
                                   HTML("<b style='color:red;'>O aplicativo foi meticulosamente desenvolvido para atuar como um instrumento de otimização do processo de lançamento, atuando como um facilitador. No entanto, uma coisa importante a ressaltar é que sua utilização não elimina a necessidade de análises e verificações criteriosas!</b>")
                               )
                        )
                      )
             ),
             
             tabPanel("Dados", icon = icon("file-upload"),
                      sidebarLayout(
                        sidebarPanel(
                          fileInput("shape", "Upload do Shapefile dos talhões", accept = c(".zip")),
                          fileInput("grid_existente", "Carregar Grid Existente (.shp):", multiple = TRUE, accept = c('.shp','.dbf','.sbn','.sbx','.shx','.prj')),
                          
                          radioButtons("shape_input_pergunta_arudek", "Qual seria o formato do shape de entrada?",
                                       choices = list("ARUDEK.VW_GIS_POL_USO_SOLO" = 1, "Outro" = 0), selected = 1),
                          
                          conditionalPanel("input.shape_input_pergunta_arudek == 0",
                                           h3("Insira presentes no seu arquivo:"),
                                           p("O nome deve ser exatamente igual a tabela de atributos."),
                                           textInput("mudar_nome_arudek_projeto", "Projeto:", "ID_PROJETO"),
                                           textInput("mudar_nome_arudek_talhao", "Talhão:", "CD_TALHAO"),
                                           textInput("mudar_nome_arudek_ciclo", "Ciclo:", "NUM_CICLO"),
                                           textInput("mudar_nome_arudek_rotacao", "Rotação:", "NUM_ROTAC")
                          ),
                          
                          radioButtons("recomendacao_pergunta_upload", "Deseja realizar o upload do arquivo de recomendação?",
                                       choices = list("Sim" = 1, "NÃO" = 0), selected = 1),
                          
                          conditionalPanel("input.recomendacao_pergunta_upload == 1",
                                           fileInput("recomend", "Upload do arquivo de recomendação", accept = c(".csv"))),
                          
                          conditionalPanel("input.recomendacao_pergunta_upload == 0",
                                           h3("Informe a intensidade desejada para as parcelas"),
                                           p("Nota: Informar a quantos hectares serão necessários para cada parcela alocada."),
                                           numericInput("recomend_intensidade", "1:", value = 3)
                          ),
                          
                          radioButtons("parcelas_existentes_lancar", "Deseja informar as parcelas já existentes?",
                                       choices = list("Sim" = 1, "NÃO" = 0), selected = 0),
                          
                          conditionalPanel("input.parcelas_existentes_lancar == 1",
                                           fileInput("parc_exist", "Upload do Shapefile das parcelas já existentes", accept = c(".zip"))),
                          
                          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
                          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC")),
                          
                          p("Notas:"),
                          p("S* = Sobrevivência;"),
                          p("IFQ* = Inventário Florestal Qualitativo;"),
                          p("IFC = Inventário Florestal Contínuo;"),
                          p("IPC = Inventário Florestal Pré-Corte."),
                          
                          conditionalPanel("input.tipo_parcela == 'IPC'",
                                           radioButtons("lancar_sobrevivencia", "Deseja lançar as parcelas de sobrevivência?",
                                                        choices = list("Sim" = 1, "NÃO" = 0), selected = 0)
                          ),
                          
                          sliderInput("distancia_minima", "Distância Mínima:", min = 5, max = 25, value = 20, step = 0.5),
                          actionButton("confirmar", "Confirmar")
                        ),
                        mainPanel(
                          div(class = "sobre-texto",
                              h2("Sobre os arquivos"),
                              p("Shape dos talhões: zipfile contendo todos os arquivos exportados do shapefile (ARUDEK)."),
                              p("Serão obrigatórias as seguintes colunas na tabela de atributos: AREA_HA, ID_PROJETO, ID_TALHAO, CICLO, ROTACAO."),
                              p("Recomendação: planilha csv separado por vírgulas contendo: Projeto, Talhao e N. Em que N é a quantidade de parcelas."),
                              p("Shape das parcelas históricas: zipfile contendo todos os arquivos exportados do shapefile (todas as parcelas da base de inventário para cada projeto).")
                          ),
                          verbatimTextOutput("shape_text"),
                          verbatimTextOutput("recomend_text"),
                          verbatimTextOutput("parc_exist_text"),
                          verbatimTextOutput("confirmation"),
                          
                          conditionalPanel(
                            "input.recomendacao_pergunta_upload == 0",
                            textInput("download_recomend_name", "Insira o nome do arquivo de recomendação para download:", "Recomendação-"),
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
                                     div(class = "sobre-texto",
                                         h2("Gerar parcelas"),
                                         p("Pressione o botão para gerar as parcelas."),
                                         p("Dependendo da quantidade de talhões e parcelas recomendadas, o processo pode levar alguns minutos.")
                                     ),
                                     actionButton("gerar_parcelas", "Gerar Parcelas")
                                   ),
                                   mainPanel(
                                     div(id = "progress-container", style = "width: 100%; background-color: #f3f3f3; padding: 3px; position: relative;",
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
                                     column(2, offset = 1,
                                            actionButton("anterior", "ANTERIOR", class = "btn btn-dark")
                                     ),
                                     column(2,
                                            actionButton("proximo", "PRÓXIMO", class = "btn btn-dark")
                                     ),
                                     column(5,
                                            actionButton("gerar_parcelas", "GERAR NOVAMENTE AS PARCELAS", class = "btn btn-danger")
                                     )
                                   ),
                                   br(), br(),
                                   fluidRow(
                                     column(10, offset = 1,
                                            div(style = "color:red; font-weight:bold; font-size:16px; text-align:justify;",
                                                "O número de parcelas alocadas pode diferir do número recomendado, em virtude das premissas adotadas. Nesses casos avaliar a plotagem e checagem manuais dentro do ArcGis Pro!"
                                            )
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
                                     
                                     textInput("nome_arquivo", "Insira o nome do arquivo para download:", 
                                               value = paste0("Parcelas_", Sys.Date())),
                                     
                                     br(),
                                     
                                     downloadButton("download_result", "DOWNLOAD PARCELAS", class = "btn btn-dark"),
                                     
                                     br(), br(),
                                     
                                     div(style = "color:red; font-weight:bold;",
                                         "Nota: Será necessário alterar o nome para cada arquivo a ser salvo.")
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
