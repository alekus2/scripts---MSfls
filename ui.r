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
  
  navbarPage("AutoParc - LanÃ§amento de Parcelas", theme = shinytheme("sandstone"),
             
             windowTitle = "Window Title",
             tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
             tabPanel("Sobre", icon = icon("info"), tags$style(button_color_css),
                      tags$div(class = "sobre-texto",
                               tags$h2("Sobre"),
                               tags$p("Ferramenta desenvolvida em Shiny (R) para o lanÃ§amento de parcelas semi-aleatÃ³rias, que integra informaÃ§Ãµes de recomendaÃ§Ã£o, shapefile dos talhÃµes e parcelas histÃ³ricas. Essa aplicaÃ§Ã£o permite aos usuÃ¡rios realizar o lanÃ§amento de parcelas de maneira automÃ¡tica e depois exportar o shapefile das parcelas."),
                               HTML("<b style='color:red;'>O aplicativo foi meticulosamente desenvolvido para atuar como um instrumento de otimizaÃ§Ã£o do processo de lanÃ§amento, atuando como um facilitador. No entanto, Ã© importante ressaltar que sua utilizaÃ§Ã£o nÃ£o elimina a necessidade de anÃ¡lises e verificaÃ§Ãµes criteriosas!</b>"))),
             tabPanel("Dados", fluid = T, icon = icon("file-upload"), tags$style(button_color_css),
                      sidebarLayout(
                        sidebarPanel(
                          fileInput("shape", "Upload do Shapefile dos talhÃµes", accept = c(".zip")),
                          
                          radioButtons("shape_input_pergunta_arudek", label = h3("Qual Ã© o formato do shape de entrada?"),
                                       choices = list("ARUDEK.VW_GIS_POL_USO_SOLO" = 1, "Outro" = 0), selected = 1),
                          conditionalPanel("input.shape_input_pergunta_arudek == 0",
                                           tags$h3("Insira presentes no seu arquivo:"),
                                           tags$p("O nome deve ser exatamente igual a tabela de atributos."),
                                           textInput(inputId = "mudar_nome_arudek_projeto",
                                                     label = "Projeto:",
                                                     value = "ID_PROJETO"),
                                           textInput(inputId = "mudar_nome_arudek_talhao",
                                                     label = "TalhÃ£o:",
                                                     value = "CD_TALHAO"),
                                           textInput(inputId = "mudar_nome_arudek_ciclo",
                                                     label = "Ciclo:",
                                                     value = "NUM_CICLO"),
                                           textInput(inputId = "mudar_nome_arudek_rotacao",
                                                     label = "RotaÃ§Ã£o:",
                                                     value = "NUM_ROTAC")),
                          
                          radioButtons("recomendacao_pergunta_upload", label = h3("Deseja realizar o upload do arquivo de recomendaÃ§Ã£o?"),
                                       choices = list("Sim" = 1, "NÃ£o" = 0), selected = 1),
                          
                          conditionalPanel("input.recomendacao_pergunta_upload == 1",
                                           fileInput("recomend", "Upload do arquivo de recomendaÃ§Ã£o", accept = c(".csv"))),
                          
                          tags$h3("Informe a intensidade amostral desejada para plotagem de parcelas"),
                          numericInput("intensidade_amostral", label = h3("1:"), value = 5),
                          
                          
                          radioButtons("parcelas_existentes_lancar", label = h3("Deseja informar as parcelas jÃ¡ existentes?"),
                                       choices = list("Sim" = 1, "NÃ£o" = 0), selected = 0),
                          
                          conditionalPanel("input.parcelas_existentes_lancar == 1",
                                           fileInput("parc_exist", "Upload do Shapefile das parcelas jÃ¡ existentes", accept = c(".zip"))),
                          
                          selectizeInput("forma_parcela", "Forma Parcela:", choices = c("CIRCULAR", "RETANGULAR")),
                          
                          selectizeInput("tipo_parcela", "Tipo da Parcela:", choices = c("S30", "S90", "IFQ6", "IFQ12", "IFC", "IPC"), selected = NULL),
                          tags$p("Notas:"), 
                          tags$p("S* = SobrevivÃªncia;"), 
                          tags$p("IFQ* = InventÃ¡rio Florestal Qualitativo;"),                                 
                          tags$p("IFC = InventÃ¡rio Florestal ContÃ­nuo;"), 
                          tags$p("IPC = InventÃ¡rio Florestal PrÃ©-Corte."),
                          conditionalPanel("input.tipo_parcela == 'IPC'", 
                                           radioButtons("lancar_sobrevivencia", label = h3("Deseja lanÃ§ar as parcelas de sobrevivÃªncia?"),
                                                        choices = list("Sim" = 1, "NÃ£o" = 0), selected = 0)),
                          sliderInput("distancia_minima", label = h3("DistÃ¢ncia MÃ­nima"), min = 5, max = 25, value = 20, step = 0.5),
                          actionButton("confirmar", "Confirmar")
                        ),
                        mainPanel(
                          tags$div(class = "sobre-texto",
                                   tags$h2("Sobre os arquivos"),
                                   tags$p("Shape dos talhÃµes: zipfile contendo todos os arquivos exportados do shapefile (ARUDEK)."),
                                   tags$p("SÃ£o obrigatÃ³rias as seguintes colunas na tabela de atributos: AREA_HA, ID_PROJETO, ID_TALHAO, CICLO, ROTACAO."),
                                   tags$p("RecomendaÃ§Ã£o: planilha csv separado por vÃ­rgulas contendo: Projeto, Talhao e N. Em que N Ã© a quantidade de parcelas."),
                                   tags$p("Shape das parcelas histÃ³ricas: zipfile contendo todos os arquivos exportados do shapefile (todas as parcelas da base de invetÃ¡rio para cada projeto).")),
                          verbatimTextOutput("shape_text"),
                          verbatimTextOutput("recomend_text"),
                          verbatimTextOutput("parc_exist_text"),
                          verbatimTextOutput("confirmation"), 
                          conditionalPanel(
                            "input.recomendacao_pergunta_upload == 0",
                            textInput(inputId = "download_recomend_name",
                                      label = "Insira o nome do arquivo de recomendaÃ§Ã£o para download:",
                                      value = "RecomendaÃ§Ã£o-"),
                            downloadButton("download_recomend", "Download da RecomendaÃ§Ã£o criada*"),
                            tags$p("*DisponÃ­vel apÃ³s o upload das demais inforaÃ§Ãµes")
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
                                              tags$p("Pressione o botÃ£o para gerar as parcelas."),
                                              tags$p("Dependendo da quantidade de talhÃµes e parcelas recomendadas, o processo pode levar alguns minutos.")),
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
                                              "ConcluÃ­do")
                                   )
                                 )),
                        tabPanel("Parcelas Plotadas", icon = icon("map"),
                                 sidebarLayout(
                                   sidebarPanel(uiOutput("index_filter"),
                                                actionButton("anterior", "Anterior"),
                                                actionButton("proximo", "PrÃ³ximo"),
                                                tags$p("Para recalcular a distribuiÃ§Ã£o do talhÃ£o:"),
                                                actionButton("gerar_novamente", "Gerar novamente as parcelas")),
                                   mainPanel(
                                     plotOutput("plot"),
                                     HTML("<b style='color:red;'>O nÃºmero de parcelas alocadas pode diferir do nÃºmero recomendado, em virtude das premissas adotadas. Nesses casos avaliar a plotagem e checagem manuais dentro do ArcGis Pro!</b>")
                                   )
                                 )),
                        tabPanel("Download", icon = icon("download"),
                                 sidebarLayout(
                                   sidebarPanel(tags$div(class = "sobre-texto",
                                                         tags$h2("Download"),
                                                         tags$p("Arquivo gerado com base nas especificaÃ§Ãµes.")),
                                                textInput(inputId = "download_name",
                                                          label = "Insira o nome do arquivo para download:",
                                                          value = "Parcelas_2023-04-20"),
                                                tags$div(class = "sobre-texto",
                                                         tags$p("Nota: Ã© necessÃ¡rio alterar o nome para cada arquivo a ser salvo."))),
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
