# Converter os códigos para inteiros e criar a query correta
cod_talhao = df['CD_USO_SOL'].astype(int).unique()
query = f"CD_USO_SOL IN ({','.join(map(str, cod_talhao))})"

# Criar uma camada temporária com a query aplicada
layer_temp = "TalhoesSelecionados_Layer"
arcpy.MakeFeatureLayer_management(input_layer, layer_temp, query)

# Agora sim, exportar apenas os talhões filtrados
output_shapefile = os.path.join(workspace, "TalhoesSelecionados.shp")
arcpy.CopyFeatures_management(layer_temp, output_shapefile)
arcpy.AddMessage(f"Shapefile exportado com {arcpy.GetCount_management(output_shapefile)[0]} talhões.")

# Continuar com o processamento normal...
