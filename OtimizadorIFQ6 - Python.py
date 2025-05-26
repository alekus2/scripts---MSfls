# ... (código anterior permanece inalterado)

df_D_resultados["%_Sobrevivência"] = (
    (valid/tot*100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
)

# Antes de realizar cálculos que envolvem %_Sobrevivência, convertemos para decimal
df_D_resultados["%_Sobrevivência_decimal"] = df_D_resultados["%_Sobrevivência"].str.rstrip('%')  # Remove o símbolo de porcentagem
df_D_resultados["%_Sobrevivência_decimal"] = pd.to_numeric(df_D_resultados["%_Sobrevivência_decimal"], errors='coerce')  # Converte para numérico
df_D_resultados["%_Sobrevivência_decimal"] = df_D_resultados["%_Sobrevivência_decimal"] / 100  # Converte de porcentagem para decimal

# Cálculos que dependem de %_Sobrevivência
df_D_resultados["Pits por sob"] = (df_D_resultados["Stand (tree/ha)"] / df_D_resultados["%_Sobrevivência_decimal"]).apply(math.ceil)
df_D_resultados["CHECK pits"] = df_D_resultados["Pits por sob"] - df_D_resultados["Pits/ha"]

# Convertendo de volta para o formato de porcentagem
df_D_resultados["%_Sobrevivência"] = (df_D_resultados["%_Sobrevivência_decimal"] * 100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))

# Remover a coluna temporária se não for mais necessária
df_D_resultados.drop(columns=["%_Sobrevivência_decimal"], inplace=True)

# ... (código posterior permanece inalterado)