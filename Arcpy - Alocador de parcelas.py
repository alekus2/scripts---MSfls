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
        colunas_esperadas = ['CD_USO_SOL', 'AREA_HA']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                arcpy.AddError(f"Erro: A coluna {coluna} não foi encontrada no arquivo do Excel.")
                return

        cod_talhao = df['CD_USO_SOL'].astype(int)
        area_talhao = df['AREA_HA'].astype(float)
        query = f"CD_USO_SOL IN ({','.join(map(str, cod_talhao.unique()))})"

        output_shapefile = os.path.join(workspace, "TalhoesSelecionados.shp")
        arcpy.Select_analysis(input_layer, output_shapefile, query)

        cell_size = (area_talhao ** 0.5) / 10
        fishnet_shp = os.path.join(workspace, "Fishnet.shp")
        arcpy.CreateFishnet_management(fishnet_shp, "", "", cell_size, cell_size, "", "", output_shapefile, "NO_LABELS", "", "POLYGON")

        buffer_shp = os.path.join(workspace, "Buffer_30m.shp")
        arcpy.Buffer_analysis(output_shapefile, buffer_shp, "-30 Meters")

        intersect_shp = os.path.join(workspace, "Intersected.shp")
        arcpy.Intersect_analysis([buffer_shp, fishnet_shp], intersect_shp)

        pontos_count = int(arcpy.GetCount_management(intersect_shp)[0])
        planejado = len(cod_talhao) * 9
        if pontos_count != planejado:
            arcpy.AddWarning(f"Quantidade de pontos ({pontos_count}) diferente do planejado ({planejado}).")

        merged_shp = os.path.join(workspace, "Final_Points.shp")
        arcpy.Merge_management([intersect_shp], merged_shp)
        arcpy.AddMessage("Processo concluído.")
