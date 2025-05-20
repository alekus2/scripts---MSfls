import math

def arredondamento_banco(x):
    inteiro = math.floor(x)
    frac = x - inteiro
    if frac > 0.5:
        return inteiro + 1
    elif frac < 0.5:
        return inteiro
    else:
        # frac == 0.5 → arredonda para o inteiro par mais próximo
        return inteiro if (inteiro % 2 == 0) else inteiro + 1

# supondo que você já tenha:
# df_tabela["Pits por sob"] = df_tabela["Stand (tree/ha)"] / pct

# basta agora:
df_tabela["Pits por sob"] = df_tabela["Pits por sob"].apply(arredondamento_banco)
