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
        self.description = "Filtra e exporta parcelas com base no ID_TALHAO."
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

            colunas_esperadas = ['ID_PROJETO', 'CD_TALHAO']
            for coluna in colunas_esperadas:
                if coluna not in df.columns:
                    arcpy.AddError(f"Erro: A coluna {coluna} não foi encontrada no Excel.")
                    return

            df['CD_TALHAO'] = df['CD_TALHAO'].astype(str).str.zfill(2)
            df['ID_TALHAO'] = df['ID_PROJETO'].astype(str).str.strip() + df['CD_TALHAO']

            df.to_excel(base_path, index=False)
            arcpy.AddMessage("Excel atualizado com a coluna ID_TALHAO corrigida.")

            id_talhoes = df['ID_TALHAO'].dropna().unique()

            field_names = [f.name for f in arcpy.ListFields(input_layer)]
            if "ID_TALHAO" not in field_names:
                arcpy.AddMessage("Criando campo 'ID_TALHAO' temporariamente na camada base de dados...")
                arcpy.AddField_management(input_layer, "ID_TALHAO", "TEXT", field_length=50)

            with arcpy.da.UpdateCursor(input_layer, ["ID_PROJETO", "CD_TALHAO", "ID_TALHAO"]) as cursor:
                for row in cursor:
                    if row[0] and row[1]:
                        novo_id_talhao = f"{str(row[0]).strip()}{str(row[1]).zfill(2)}"
                        arcpy.AddMessage(f"Atualizando ID_TALHAO: {row[2]} → {novo_id_talhao}")
                        row[2] = novo_id_talhao
                        cursor.updateRow(row)

            camada_valores = []
            with arcpy.da.SearchCursor(input_layer, ["ID_TALHAO"]) as cursor:
                for row in cursor:
                    if row[0]:
                        camada_valores.append(row[0].strip())

            arcpy.AddMessage(f"Valores em ID_TALHAO na camada: {camada_valores}")
            arcpy.AddMessage(f"Valores esperados de ID_TALHAO (do Excel): {list(id_talhoes)}")

            id_talhoes_str = ",".join([f"'{x.strip()}'" for x in id_talhoes])
            query = f"ID_TALHAO IN ({id_talhoes_str})"
            arcpy.AddMessage(f"Query SQL gerada: {query}")

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

            cell_size = (df['AREA_HA'].mean() ** 0.5) / 9
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
            planejado = len(id_talhoes)
            if pontos_count != planejado:
                arcpy.AddWarning(f"Quantidade de pontos ({pontos_count}) diferente do planejado ({planejado}).")

            merged_shp = os.path.join(workspace, "Final_Points.shp")
            arcpy.Merge_management([intersect_shp], merged_shp)
            arcpy.AddMessage("Processo concluído.")

            if "ID_TALHAO" not in [f.name for f in arcpy.ListFields(merged_shp)]:
                arcpy.AddField_management(merged_shp, "ID_TALHAO", "TEXT", field_length=50)

            with arcpy.da.UpdateCursor(merged_shp, ["ID_PROJETO", "CD_TALHAO", "ID_TALHAO"]) as cursor:
                for row in cursor:
                    if row[0] and row[1]:
                        row[2] = f"{str(row[0]).strip()}{str(row[1]).zfill(2)}"
                        cursor.updateRow(row)

            arcpy.AddMessage("Campo 'ID_TALHAO' atualizado no shapefile final.")

        except Exception as e:
            arcpy.AddError(f"Erro ao processar o arquivo Excel: {e}")
