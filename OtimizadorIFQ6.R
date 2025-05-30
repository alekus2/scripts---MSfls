# 1. Defina a pasta onde estão todas as suas planilhas .xlsx
pasta_dados <- "F:/Qualidade_Florestal/02- MATO GROSSO DO SUL/11- Administrativo Qualidade MS/00- Colaboradores/17 - Alex Vinicius/Automação em R/OtimizadorIFQ6/dados"

# 2. Liste todas as .xlsx na pasta
todos_xlsx <- list.files(
  path        = pasta_dados,
  pattern     = "\\.xlsx$",
  full.names  = TRUE
)

# 3. Separe o cadastro SGF dos demais IFQ6
cadastro <- todos_xlsx[grepl("SGF", toupper(basename(todos_xlsx)))]
ifq6      <- setdiff(todos_xlsx, cadastro)

# 4. Monte o vetor final, colocando o cadastro primeiro (é ele quem a função identifica)
arquivos <- c(
  cadastro,
  ifq6
)

# 5. Confira pra ter certeza
stopifnot(all(file.exists(arquivos)))  # aborta se algum não existir
print(arquivos)

# 6. Chame a função
OtimizadorIFQ6(arquivos)
