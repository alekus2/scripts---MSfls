nome_arquivo <- basename(p)
if (str_detect(nome_arquivo, regex("lebatec", ignore_case = TRUE))) {
  base <- "lebatec"
} else if (str_detect(nome_arquivo, regex("bravore", ignore_case = TRUE))) {
  base <- "bravore"
} else if (str_detect(nome_arquivo, regex("propria", ignore_case = TRUE))) {
  base <- "propria"
} else {
  message("Arquivo sem equipe identificada automaticamente: ", nome_arquivo)
  escolha <- ""
  while (!escolha %in% c("1", "2", "3")) {
    escolha <- readline("Selecione equipe (1-LEBATEC, 2-BRAVORE, 3-PROPRIA): ")
  }
  base <- c("lebatec", "bravore", "propria")[as.integer(escolha)]
}
