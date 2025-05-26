# Após criar df_final, df_tabela e df_D_resultados, adicione estas linhas para depuração

print("Verificando NaN em df_final:")
print(df_final.isna().sum())
print("Linhas com NaN em df_final:")
print(df_final[df_final.isna().any(axis=1)])

print("Verificando NaN em df_tabela:")
print(df_tabela.isna().sum())
print("Linhas com NaN em df_tabela:")
print(df_tabela[df_tabela.isna().any(axis=1)])

print("Verificando NaN em df_D_resultados:")
print(df_D_resultados.isna().sum())
print("Linhas com NaN em df_D_resultados:")
print(df_D_resultados[df_D_resultados.isna().any(axis=1)])