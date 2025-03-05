import arcpy
import os
import pandas as pd

class Toolbox(object):
    def __init__(self):
        self.label = "Alocador de parcelas"
        self.alias = "alocator_toolbox"
        self.tools = [AlocadorDeParcelas]

class AlocadorDeParcelas(object):
    def __init__(self):
        self.label = "Alocar parcelas"
        self.description = "Verifica dentro da Base de dados, conta CD_USO_SOL e faz um query e exporta o query como um shapefile"
        self.canRunInBackground = False

    def getParameterInfo(self):
        param_excel = arcpy.Parameter(
            displayName="Arquivo Excel com a programação",
            name="base_path",
            datatype="DEFile",
            parameterType="Required",
            direction="Input"
        )

        param_workspace = arcpy.Parameter(
            displayName="Pasta de saída",
            name="workspace",
            datatype="DEWorkspace",
            parameterType="Required",
            direction="Input"
        )

        param_layer = arcpy.Parameter(
            displayName="Camada base de dados",
            name="input_layer",
            datatype="DEFeatureClass",
            parameterType="Required",
            direction="Input"
        )

        return [param_excel, param_workspace, param_layer]

    def execute(self, parameters, messages):
        base_path = parameters[0].valueAsText
        workspace = parameters[1].valueAsText
        input_layer = parameters[2].valueAsText

        if not arcpy.Exists(base_path):
            arcpy.AddError(f"Erro: O arquivo {base_path} não foi encontrado.")
            return

        arcpy.env.workspace = workspace
        df = pd.read_excel(base_path)
        colunas_esperadas = ['CD_USO_SOLO', 'AREA_HA']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                arcpy.AddError(f"Erro: A coluna {coluna} não foi encontrada no arquivo do Excel.")
                return
            
        area_talhao = df['AREA_HA'].astype(float)
        
        field_names = [f.name for f in arcpy.ListFields(input_layer)]
        if "CD_USO_SOLO" not in field_names:
            arcpy.AddError("Erro: Campo 'CD_USO_SOLO' não encontrado na camada. Verifique o nome exato.")
            return

        field_list = arcpy.ListFields(input_layer, "CD_USO_SOLO")
        field_type = field_list[0].type  

        cod_talhao = df['CD_USO_SOLO'].dropna().astype(str).unique()

        pontos_coletados = len(cod_talhao)
        if pontos_coletados:
            arcpy.AddWarning(f"Quantidade de pontos coletados: ({pontos_coletados}).")

        if field_type in ["String", "Text"]:
            query = f"CD_USO_SOLO IN ({','.join(f'\'{c}\'' for c in cod_talhao)})"
        else:
            query = f"CD_USO_SOLO IN ({','.join(map(str, cod_talhao))})"

        arcpy.AddMessage(f"Query SQL gerada: {query}")

        layer_temp = "TalhoesSelecionados_Layer"
        arcpy.MakeFeatureLayer_management(input_layer, layer_temp, query)

        output_shapefile = os.path.join(workspace, "TalhoesSelecionados.shp")
        arcpy.CopyFeatures_management(layer_temp, output_shapefile)
        arcpy.AddMessage(f"Shapefile exportado com {arcpy.GetCount_management(output_shapefile)[0]} talhões.")

        desc = arcpy.Describe(output_shapefile)
        origin_coord = f"{desc.extent.XMin} {desc.extent.YMin}"
        y_axis_coord = f"{desc.extent.XMin} {desc.extent.YMax}"
        corner_coord = f"{desc.extent.XMax} {desc.extent.YMax}"

        cell_size = (area_talhao.mean() ** 0.5) / 9
        fishnet_shp = os.path.join(workspace, "Fishnet.shp")

        arcpy.CreateFishnet_management(
            out_feature_class=fishnet_shp,
            origin_coord=origin_coord,
            y_axis_coord=y_axis_coord,
            cell_width=cell_size,
            cell_height=cell_size,
            number_rows="",
            number_columns="",
            corner_coord=corner_coord,
            labels="NO_LABELS",
            template=output_shapefile,
            geometry_type="POLYGON"
        )

        buffer_shp = os.path.join(workspace, "Buffer_30m.shp")
        arcpy.Buffer_analysis(output_shapefile, buffer_shp, "-30 Meters")

        intersect_shp = os.path.join(workspace, "Intersected.shp")
        arcpy.Intersect_analysis([buffer_shp, fishnet_shp], intersect_shp)

        pontos_count = int(arcpy.GetCount_management(intersect_shp)[0])
        planejado = len(cod_talhao)
        if pontos_count != planejado:
            arcpy.AddWarning(f"Quantidade de pontos ({pontos_count}) diferente do planejado ({planejado}).")

        merged_shp = os.path.join(workspace, "Final_Points.shp")
        arcpy.Merge_management([intersect_shp], merged_shp)
        arcpy.AddMessage("Processo concluído.")