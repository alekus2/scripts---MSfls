# ui.R
library(shiny)
library(shinythemes)

bracell_primary   <- "#007E69"
bracell_secondary <- "#5f8b27"
bracell_white     <- "#FFFFFF"

ui <- tagList(
  tags$head(
    tags$style(HTML(paste0("
      body { background: ", bracell_white, "; font-family: 'Segoe UI'; }
      .navbar { background: ", bracell_primary, " !important; }
      .navbar-default .navbar-brand,
      .navbar-default .navbar-nav > li > a { color: ", bracell_white, " !important; }
      .navbar-nav > li.active > a { color: ", bracell_secondary, " !important; }
      .tab-content { padding: 20px; background: #f4f4f4; border-top: 2px solid ", bracell_secondary, "; }
      .btn { background: ", bracell_secondary, "; color: white; font-weight: bold; }
      .btn:hover, .btn:focus { background: ", bracell_primary, "; outline: none; }
      .sobre-texto { font-size: 16px; color: #000; text-align: justify; }
      .sobre-texto h2 { font-size: 24px; color: ", bracell_primary, "; }
    ")))
  ),

  navbarPage(
    title = div(img(src="logo.png", height="40px"), "ALOCADOR DE PARCELAS"),
    theme = shinytheme("flatly"),

    tabPanel("Dados", icon = icon("file-upload"),
      sidebarLayout(
        sidebarPanel(
          fileInput("shape", "Shapefile dos talhões (.zip)", accept = ".zip"),
          radioButtons("shape_fmt", "Formato do shape:",
            choices = c("Bracell SDE" = 1, "Outro" = 0), selected = 1),
          conditionalPanel("input.shape_fmt == 0",
            textInput("col_projeto", "Coluna Projeto:", "ID_PROJETO"),
            textInput("col_talhao", "Coluna Talhão:",  "CD_TALHAO"),
            textInput("col_ciclo",   "Coluna Ciclo:",   "NUM_CICLO"),
            textInput("col_rotac",   "Coluna Rotação:", "NUM_ROTAC")
          ),

          radioButtons("has_recomend", "Upload de recomendação?",
            choices = c("Sim" = 1, "Não" = 0), selected = 1),
          conditionalPanel("input.has_recomend == 1",
            fileInput("recomend", "CSV de recomendação", accept = ".csv")
          ),
          conditionalPanel("input.has_recomend == 0",
            numericInput("recomend_intensidade",
              "Intensidade (ha/ponto) p/ cálculo de Num.parc:", value = 3, min = 0.1)
          ),

          numericInput("intensidade_amostral",
            "Intensidade (ha/ponto) → espaçamento [m]:", value = 5, min = 0.1),

          radioButtons("has_existentes", "Parcelas existentes?",
            choices = c("Sim" = 1, "Não" = 0), selected = 0),
          conditionalPanel("input.has_existentes == 1",
            fileInput("parc_exist", "Shapefile existente (.zip)", accept = ".zip")
          ),

          selectizeInput("forma_parcela", "Forma da parcela:",
            choices = c("CIRCULAR","RETANGULAR")),
          selectizeInput("tipo_parcela", "Tipo da parcela:",
            choices = c("S30","S90","IFQ6","IFQ12","IFC","IPC")),

          actionButton("confirmar", "Confirmar Dados", class="btn btn-danger")
        ),

        mainPanel(
          verbatimTextOutput("shape_text"),
          verbatimTextOutput("recomend_text"),
          verbatimTextOutput("parc_exist_text"),
          verbatimTextOutput("confirmation")
        )
      )
    ),

    tabPanel("Plot & Download", icon = icon("map"),
      sidebarLayout(
        sidebarPanel(
          actionButton("gerar_parcelas", "Gerar Parcelas", class = "btn btn-danger"),
          div(id="progress-container",
            div(id="progress-bar", style="
              width:0%; height:20px; background:#4CAF50; text-align:center; color:white;
            ")
          ),
          div(id="completed-msg", style="display:none; color:green; font-weight:bold;", "Concluído!")
        ),
        mainPanel(
          plotOutput("map_plot", height="600px"),
          textInput("nome_arquivo", "Nome do shapefile:", value = paste0("Parcelas_", format(Sys.Date(),"%Y%m%d"))),
          downloadButton("download_result", "Download ZIP", class="btn btn-danger")
        )
      )
    )
  ),

  tags$script(HTML("
    Shiny.addCustomMessageHandler('update_progress', function(p) {
      $('#progress-bar').css('width', p+'%').text(p+'%');
    });
    Shiny.addCustomMessageHandler('show_completed', function(m) {
      $('#completed-msg').show();
    });
  "))
)
