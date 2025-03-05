if field_type in ["Integer", "Double", "Float"]:  # Verificando tipos numéricos
    # Filtra valores nulos
    cod_talhao = [c for c in cod_talhao if pd.notnull(c)]  # Mantém apenas valores válidos
    if not cod_talhao:
        arcpy.AddError("Erro: Não há códigos válidos em 'CD_USO_SOLO'.")
        return

    # Gera a query sem aspas, pois os valores são numéricos
    query = f"CD_USO_SOLO IN ({','.join(map(str, cod_talhao))})"
else:
    arcpy.AddError("Erro: O campo 'CD_USO_SOLO' não é numérico.")
    return