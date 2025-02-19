def getParameterInfo(self):
    params = [
        # ... outros parâmetros ...
        arcpy.Parameter(displayName="Power",
                        name="power",
                        datatype="GPDouble",
                        parameterType="Required",
                        direction="Input"),
        arcpy.Parameter(displayName="Cell Size",
                        name="cell_size",
                        datatype="GPDouble",
                        parameterType="Required",
                        direction="Input")
    ]
    return params

def execute(self, parameters, messages):
    # ... leitura do CSV e configurações iniciais ...

    power = parameters[2].value  # Pega o valor do parâmetro Power
    cellSize = parameters[3].value  # Pega o valor do parâmetro Cell Size

    # ... lógica para IDW e exportação de mapas ...

    for unit in unitList:
        # ... código existente para criar camadas e executar IDW ...
        
        # Adicionar lógica para gerar e exportar mapas
        mxd = arcpy.mapping.MapDocument("CURRENT")
        df = arcpy.mapping.ListDataFrames(mxd, "Layers")[0]
        newLayer = arcpy.mapping.Layer(rasterOutputPath)
        arcpy.mapping.AddLayer(df, newLayer)
        arcpy.mapping.ExportToPNG(mxd, os.path.join(output_folder, f"{feat}_{unit}.png"))