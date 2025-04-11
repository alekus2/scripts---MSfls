library(shiny)
library(shinythemes)

# Cores da Bracell
bracell_primary <- "#003366"  # azul escuro
bracell_secondary <- "#0077C8"  # azul claro
bracell_white <- "#FFFFFF"

ui <- fluidPage(
  theme = shinytheme("flatly"),
  tags$head(
    tags$style(HTML(paste0("
      body {
        background-color: ", bracell_white, ";
        color: ", bracell_primary, ";
        font-family: 'Segoe UI', sans-serif;
      }

      .navbar {
        background-color: ", bracell_primary, " !important;
      }

      .navbar-default .navbar-nav > li > a,
      .navbar-default .navbar-brand {
        color: ", bracell_white, " !important;
      }

      .tabbable > .nav > li[class=active] > a {
        background-color: ", bracell_secondary, " !important;
        color: ", bracell_white, " !important;
      }

      .btn {
        background-color: ", bracell_secondary, ";
        color: ", bracell_white, ";
        border: none;
      }

      .btn:hover {
        background-color: ", bracell_primary, ";
        color: ", bracell_white, ";
      }

      .well {
        background-color: #f9f9f9;
        border: 1px solid ", bracell_secondary, ";
      }

      .shiny-input-container {
        margin-bottom: 15px;
      }
    ")))
  ),
  
  navbarPage(
    title = "Alocação de Parcelas",
    tabPanel("Sobre", 
             fluidRow(
               column(12,
                      h2("Sistema de Alocação de Parcelas", style = "color: #003366;"),
                      p("Este aplicativo foi desenvolvido para auxiliar na alocação automática de parcelas dentro de talhões agrícolas utilizando dados espaciais e recomendações técnicas.",
                        style = "font-size:16px;")
               )
             )
    ),
    tabPanel("Dados",
             sidebarLayout(
               sidebarPanel(
                 fileInput("shapefile", "Carregar shapefile do talhão (.zip):", accept = ".zip"),
                 fileInput("csv", "Carregar arquivo de recomendações (.csv):", accept = ".csv"),
                 actionButton("processar", "Processar dados")
               ),
               mainPanel(
                 h4("Pré-visualização dos dados"),
                 tableOutput("preview_data")
               )
             )
    ),
    tabPanel("Resultados",
             fluidRow(
               column(6,
                      plotOutput("mapa_plot")
               ),
               column(6,
                      verbatimTextOutput("info_resultados")
               )
             )
    ),
    tabPanel("Parcelas Plotadas",
             fluidRow(
               column(12,
                      leafletOutput("mapa_interativo", height = 500)
               )
             )
    ),
    tabPanel("Download",
             fluidRow(
               column(12,
                      downloadButton("download_shp", "Download das Parcelas (Shapefile)")
               )
             )
    )
  )
)
