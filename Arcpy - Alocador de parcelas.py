# Obter nome correto do campo
field_names = [f.name for f in arcpy.ListFields(input_layer)]
if "CD_USO_SOL" not in field_names:
    arcpy.AddError("Erro: Campo 'CD_USO_SOL' não encontrado na camada. Verifique o nome exato.")
    return

# Descobrir o tipo do campo no ArcGIS
field_list = arcpy.ListFields(input_layer, "CD_USO_SOL")
field_type = field_list[0].type  # Obtém o tipo do campo

# Converter os códigos e montar a query correta
cod_talhao = df['CD_USO_SOL'].dropna().astype(str).unique()  # Garantir que são strings válidas

if field_type in ["String", "Text"]:
    query = f"CD_USO_SOL IN ({','.join(f"'{c}'" for c in cod_talhao)})"  # Aspas para texto
else:
    query = f"CD_USO_SOL IN ({','.join(map(str, cod_talhao))})"  # Sem aspas para números

arcpy.AddMessage(f"Query SQL gerada: {query}")

# Criar camada filtrada corretamente
layer_temp = "TalhoesSelecionados_Layer"
arcpy.MakeFeatureLayer_management(input_layer, layer_temp, query)

# Exportar shapefile apenas com os talhões filtrados
output_shapefile = os.path.join(workspace, "TalhoesSelecionados.shp")
arcpy.CopyFeatures_management(layer_temp, output_shapefile)
arcpy.AddMessage(f"Shapefile exportado com {arcpy.GetCount_management(output_shapefile)[0]} talhões.")
