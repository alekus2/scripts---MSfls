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

