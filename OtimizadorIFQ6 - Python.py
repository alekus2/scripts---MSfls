# --- definindo as listas de códigos conforme sua regra ---
# todas as classes de A até E, inclusive (mesmo as que representam falha)
classes_ate_E = ["A", "B", "C", "D", "E"]
# códigos que definem falhas
falhas = ["M", "H", "F", "L", "S"]

# --- recalculando Stand (tree/ha) corretamente ---
df_tabela["Stand (tree/ha)"] = (
    # soma de todas as covas A–E
    df_tabela[classes_ate_E].sum(axis=1)
    # menos a soma das falhas
    - df_tabela[falhas].sum(axis=1)
) * 10000 / df_tabela["nm_area_parcela"]

