# Pacotes exigidos -----------------------------------------------

pacotes <- c(
  "shiny",
  "shinythemes",
  "sf",
  "ggplot2",
  "dplyr",
  "tidyr",
  "hrbrthemes",
  "DT",
  "ggrepel",
  "shinycssloaders",
  "shinyjs",
  "gridExtra",
  "progress",
  "stringr"
)


novos_pacotes <- pacotes[!(pacotes %in% installed.packages()[,"Package"])]

if (length(novos_pacotes)) {
  install.packages(novos_pacotes)
}
