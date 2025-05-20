# depois de calcular df_tabela["Pits/ha"] e df_tabela["Pits por sob"], faça:

def ajusta_paridade(row):
    # arredonda os valores para inteiro
    p_ha  = int(round(row["Pits/ha"]))
    p_sob = int(round(row["Pits por sob"]))
    # se já tiverem mesma paridade (ambos pares ou ímpares), mantém
    if (p_ha % 2) == (p_sob % 2):
        return p_sob
    # se Pits/ha for ímpar e Pits por sob for par, soma 1
    if p_ha % 2 == 1 and p_sob % 2 == 0:
        return p_sob + 1
    # se Pits/ha for par e Pits por sob for ímpar, subtrai 1 (garantindo não ficar negativo)
    if p_ha % 2 == 0 and p_sob % 2 == 1:
        return max(p_sob - 1, 0)
    return p_sob  # fallback

# aplica linha a linha
df_tabela["Pits por sob"] = df_tabela.apply(ajusta_paridade, axis=1)

# e só então recalcula Check pits
df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]
