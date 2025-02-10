# Função para calcular o máximo
calcular_maximo <- function(talhao, tabela) {
  valores <- tabela[tabela$Index == talhao, "nm_parcela"]
  max_parcelas <- list()
  max_parcelas[[talhao]] <- max(as.numeric(valores), na.rm = TRUE)
  return(max_parcelas[[talhao]])
}

# Exemplo de uso
# Suponha que você tenha uma data.frame chamado "tabela"
# tabela <- data.frame(Index = c(...), nm_parcela = c(...))
# resultado <- calcular_maximo(especificar_talhao_aqui, tabela)
# print(resultado)

# Função para auto-incremento
autoIncrement <- function(parcela, count) {
  parcela <- as.integer(parcela)
  count <- as.integer(count)
  if (count <= 3) {
    return(1)
  }
  return(ifelse(parcela %% 2 != 0, 1, 0))
}

# Exemplo de uso
# resultado_auto <- autoIncrement(especificar_nm_parcela_aqui, especificar_contador_aqui)
# print(resultado_auto)


OUTRO CODIGO

# Instale o pacote arcgisbinding se ainda não o tiver instalado
# install.packages("arcgisbinding")

library(arcgisbinding)

# Função para alocar parcelas
alocar_parcelas <- function(tabela_nome) {
  # Conectar ao ArcGIS e ler a tabela
  arc.check_product()
  tabela <- arc.open(tabela_nome)
  df <- arc.data2sp(df = tabela)

  # Aplicar a lógica de contador
  df$CONTADOR <- ifelse(df$nm_parcela < 3, 1, ifelse(df$nm_parcela %% 2 != 0, 1, 0))

  # Remover as linhas com contador igual a 0
  df <- df[df$CONTADOR != 0, ]

  # Atualizar a tabela no ArcGIS
  arc.write(tabela_nome, df, overwrite = TRUE)
}

# Exemplo de uso
# alocar_parcelas("Nome da sua tabela")

