library(shiny)
ui <- fluidPage(
  tags$head(tags$style(HTML("
  #logo {
    position: absolute;
    top: 10px;
    right: 10px;
    width: 100px;
    height: auto;
    z-index: 1000;
  }
"))),
  tags$img(src = "logo.png", id = "logo"),
  tags$head(tags$style(HTML("
    .navbar-default {
      background-color: #0054A4;
    }
  "))),
  tags$style(HTML("
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
  ")),
  
  navbarPage("AutoParc - Lançamento de Parcelas", theme = shinytheme("sandstone"),
             
             windowTitle = "Window Title",
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
             tabPanel("Sobre", icon = icon("info"), tags$style(button_color_css),
                      tags$div(class = "sobre-texto",
                               tags$h2("Sobre"),
                               tags$p("Ferramenta desenvolvida em Shiny (R) para o lançamento de parcelas semi-aleatórias, que integra informações de recomendação, shapefile dos talhões e parcelas históricas. Essa aplicação permite aos usuários realizar o lançamento de parcelas de maneira automática e depois exportar o shapefile das parcelas."),
                               HTML("<b style='color:red;'>O aplicativo foi meticulosamente desenvolvido para atuar como um instrumento de otimização do processo de lançamento, atuando como um facilitador. No entanto, é importante ressaltar que sua utilização não elimina a necessidade de análises e verificações criteriosas!</b>"))),
             tabPanel("Dados", fluid = T, icon = icon("file-upload"), tags$style(button_color_css),
                      sidebarLayout(
                        sidebarPanel(
                          fileInput("shape", "Upload do Shapefile dos talhões", accept = c(".zip")),
                          
                          radioButtons("shape_input_pergunta_arudek", label = h3("Qual é o formato do shape de entrada?"),
                                       choices = list("ARUDEK.VW_GIS_POL_USO_SOLO" = 1, "Outro" = 0), selected = 1),
                          conditionalPanel("input.shape_input_pergunta_arudek == 0",
                                           tags$h3("Insira presentes no seu arquivo:"),
                                           tags$p("O nome deve ser exatamente igual a tabela de atributos."),
                                           textInput(inputId = "mudar_nome_arudek_projeto",
                                                     label = "Projeto:",
                                                     value = "ID_PROJETO"),
                                           textInput(inputId = "mudar_nome_arudek_talhao",
                                                     label = "Talhão:",
                                                     value = "CD_TALHAO"),
                                           textInput(inputId = "mudar_nome_arudek_ciclo",
                                                     label = "Ciclo:",
                                                     value = "NUM_CICLO"),
                                           textInput(inputId = "mudar_nome_arudek_rotacao",
                                                     label = "Rotação:",
                                                     value = "NUM_ROTAC")),
                          
                          radioButtons("recomendacao_pergunta_upload", label = h3("Deseja realizar o upload do arquivo de recomendação?"),
                                       choices = list("Sim" = 1, "Não" = 0), selected = 1),
                          
                          conditionalPanel("input.recomendacao_pergunta_upload == 1",
                                           fileInput("recomend", "Upload do arquivo de recomendação", accept = c(".csv"))),
                          
                          conditionalPanel("input.recomendacao_pergunta_upload == 0",
                                           tags$h3("Informe a intensidade desejada para as parcelas"),
                                           tags$p("Nota: Informar a quantos hectares serão necessários para cada parcela alocada."),
                                           numericInput("recomend_intensidade", label = h3("1:"), value = 3)
                          ),
                          
                          radioButtons("parcelas_existentes_lancar", label = h3("Deseja informar as parcelas já existentes?"),
                                       choices = list("Sim" = 1, "Não" = 0), selected = 0),
                          
                          conditionalPanel("input.parcelas_existentes_lancar == 1",
                                           fileInput("parc_exist", "Upload do Shapefile das parcelas já existentes", accept = c(".zip"))),
                          
                          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
                          
                          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC"), selected = NULL),
                          tags$p("Notas:"), 
                          tags$p("S* = Sobrevivência;"), 
                          tags$p("IFQ* = Inventário Florestal Qualitativo;"),                                 
                          tags$p("IFC = Inventário Florestal Contínuo;"), 
                          tags$p("IPC = Inventário Florestal Pré-Corte."),
                          conditionalPanel("input.tipo_parcela == 'IPC'", 
                                           radioButtons("lancar_sobrevivencia", label = h3("Deseja lançar as parcelas de sobrevivência?"),
                                                        choices = list("Sim" = 1, "Não" = 0), selected = 0)),
                          sliderInput("distancia_minima", label = h3("Distância Mínima"), min = 5, max = 25, value = 20, step = 0.5),
                          actionButton("confirmar", "Confirmar")
                        ),
                        mainPanel(
                          tags$div(class = "sobre-texto",
                                   tags$h2("Sobre os arquivos"),
                                   tags$p("Shape dos talhões: zipfile contendo todos os arquivos exportados do shapefile (ARUDEK)."),
                                   tags$p("São obrigatórias as seguintes colunas na tabela de atributos: AREA_HA, ID_PROJETO, ID_TALHAO, CICLO, ROTACAO."),
                                   tags$p("Recomendação: planilha csv separado por vírgulas contendo: Projeto, Talhao e N. Em que N é a quantidade de parcelas."),
                                   tags$p("Shape das parcelas históricas: zipfile contendo todos os arquivos exportados do shapefile (todas as parcelas da base de invetário para cada projeto).")),
                          verbatimTextOutput("shape_text"),
                          verbatimTextOutput("recomend_text"),
                          verbatimTextOutput("parc_exist_text"),
                          verbatimTextOutput("confirmation"), 
                          conditionalPanel(
                            "input.recomendacao_pergunta_upload == 0",
                            textInput(inputId = "download_recomend_name",
                                      label = "Insira o nome do arquivo de recomendação para download:",
                                      value = "Recomendação-"),
                            downloadButton("download_recomend", "Download da Recomendação criada*"),
                            tags$p("*Disponível após o upload das demais inforações")
                          )
                        )
                      )),
             tabPanel("Resultados", icon = icon("chart-bar"), tags$style(button_color_css),
                      tabsetPanel(
                        tabPanel("Status", icon = icon("clock"),
                                 sidebarLayout(
                                   sidebarPanel(
                                     tags$div(class = "sobre-texto",
                                              tags$h2("Gerar parcelas"),
                                              tags$p("Pressione o botão para gerar as parcelas."),
                                              tags$p("Dependendo da quantidade de talhões e parcelas recomendadas, o processo pode levar alguns minutos.")),
                                     actionButton("gerar_parcelas", "Gerar Parcelas")),
                                   mainPanel(
                                     tags$div(
                                       id = "progress-container",
                                       style = "width: 100%; background-color: #f3f3f3; padding: 3px; position: relative;",
                                       tags$div(
                                         id = "progress-bar",
                                         style = "width: 0%; height: 20px; background-color: #4CAF50; text-align: center; line-height: 20px; color: white;"
                                       )),
                                     tags$div(id = "completed-message", 
                                              style = "display: none; font-weight: bold; color: green;",
                                              "Concluído")
                                   )
                                 )),
                        tabPanel("Parcelas Plotadas", icon = icon("map"),
                                 sidebarLayout(
                                   sidebarPanel(uiOutput("index_filter"),
                                                actionButton("anterior", "Anterior"),
                                                actionButton("proximo", "Próximo"),
                                                tags$p("Para recalcular a distribuição do talhão:"),
                                                actionButton("gerar_novamente", "Gerar novamente as parcelas")),
                                   mainPanel(
                                     plotOutput("plot"),
                                     HTML("<b style='color:red;'>O número de parcelas alocadas pode diferir do número recomendado, em virtude das premissas adotadas. Nesses casos avaliar a plotagem e checagem manuais dentro do ArcGis Pro!</b>")
                                   )
                                 )),
                        tabPanel("Download", icon = icon("download"),
                                 sidebarLayout(
                                   sidebarPanel(tags$div(class = "sobre-texto",
                                                         tags$h2("Download"),
                                                         tags$p("Arquivo gerado com base nas especificações.")),
                                                textInput(inputId = "download_name",
                                                          label = "Insira o nome do arquivo para download:",
                                                          value = "Parcelas_2023-04-20"),
                                                tags$div(class = "sobre-texto",
                                                         tags$p("Nota: é necessário alterar o nome para cada arquivo a ser salvo."))),
                                   mainPanel(downloadButton("download_result", "Download Parcelas"))
                                 ))
                      ))
  ),
  tags$img(id = "logo", src = "logo.png"),
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