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
        self.description = "Filtra e exporta parcelas com base no CD_USO_SOLO."
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

        try:
            df = pd.read_excel(base_path)

            if 'CD_USO_SOLO' not in df.columns:
                arcpy.AddError("Erro: A coluna CD_USO_SOLO não foi encontrada no Excel.")
                return

            df['CD_USO_SOLO'] = df['CD_USO_SOLO'].astype(int)

            cd_uso_solo = df['CD_USO_SOLO'].dropna().unique()

            cd_uso_solo_str = ",".join([str(x) for x in cd_uso_solo])
            query = f"CD_USO_SOLO IN ({cd_uso_solo_str})"
            arcpy.AddMessage(f"Query SQL gerada: {query}")

            field_names = [f.name for f in arcpy.ListFields(input_layer)]
            if "CD_USO_SOLO" not in field_names:
                arcpy.AddMessage("Criando campo 'CD_USO_SOLO' temporariamente na camada base de dados...")
                arcpy.AddField_management(input_layer, "CD_USO_SOLO", "LONG", field_length=50)

            layer_temp = os.path.join(workspace, "TalhoesSelecionados.shp")
            arcpy.Select_analysis(input_layer, layer_temp, query)

            if int(arcpy.GetCount_management(layer_temp)[0]) == 0:
                arcpy.AddError("Erro: Nenhum talhão corresponde à query.")
                return

            arcpy.AddMessage(f"Shapefile exportado com {arcpy.GetCount_management(layer_temp)[0]} talhões.")

            desc = arcpy.Describe(layer_temp)
            origin_coord = f"{desc.extent.XMin} {desc.extent.YMin}"
            y_axis_coord = f"{desc.extent.XMin} {desc.extent.YMax}"
            corner_coord = f"{desc.extent.XMax} {desc.extent.YMax}"

            total_area_m2 = df['AREA_HA'].sum() * 10000
            cell_size = (total_area_m2 ** 0.5) / 9
            arcpy.AddMessage(f"Tamanho da célula calculado: {cell_size}")

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
                template=layer_temp,
                geometry_type="POLYGON"
            )

            buffer_shp = os.path.join(workspace, "Buffer_30m.shp")
            arcpy.Buffer_analysis(layer_temp, buffer_shp, "-30 Meters")

            intersect_shp = os.path.join(workspace, "Intersected.shp")
            arcpy.Intersect_analysis([buffer_shp, fishnet_shp], intersect_shp)

            pontos_count = int(arcpy.GetCount_management(intersect_shp)[0])
            planejado = len(cd_uso_solo)
            if pontos_count != planejado:
                arcpy.AddWarning(f"Quantidade de pontos ({pontos_count}) diferente do planejado ({planejado}).")

            merged_shp = os.path.join(workspace, "Final_Points.shp")
            arcpy.Merge_management([intersect_shp], merged_shp)
            arcpy.AddMessage("Processo concluído.")

            if "CD_USO_SOLO" not in [f.name for f in arcpy.ListFields(merged_shp)]:
                arcpy.AddField_management(merged_shp, "CD_USO_SOLO", "LONG", field_length=50)

            arcpy.AddMessage("Campo 'CD_USO_SOLO' atualizado no shapefile final.")

        except Exception as e:
            arcpy.AddError(f"Erro ao processar o arquivo Excel: {e}")
