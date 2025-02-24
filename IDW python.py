import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        self.label = "IDW Example Toolbox"
        self.alias = "idw_example_toolbox"
        self.tools = [CreateSampleData, IDWInterpolation]

class CreateSampleData(object):
    def __init__(self):
        self.label = "Create Sample Shapefile"
        self.description = "Cria um shapefile com pontos de exemplo para interpolação IDW."

    def getParameterInfo(self):
        return [arcpy.Parameter(displayName="Pasta de Saída",
                                name="output_folder",
                                datatype="DEFolder",
                                parameterType="Required",
                                direction="Input")]

    def execute(self, parameters, messages):
        output_folder = parameters[0].valueAsText
        shapefile_path = os.path.join(output_folder, "pontos.shp")

        if arcpy.Exists(shapefile_path):
            arcpy.Delete_management(shapefile_path)

        spatial_reference = arcpy.SpatialReference(4326)
        arcpy.CreateFeatureclass_management(output_folder, "pontos.shp", "POINT", spatial_reference=spatial_reference)
        arcpy.AddField_management(shapefile_path, "F_Sobreviv", "DOUBLE")

        points = [(-47.91, -15.78, 0.8), (-47.92, -15.79, 0.6), (-47.93, -15.76, 0.4), 
                  (-47.94, -15.74, 0.9), (-47.95, -15.77, 0.7)]

        with arcpy.da.InsertCursor(shapefile_path, ["SHAPE@XY", "F_Sobreviv"]) as cursor:
            for x, y, value in points:
                cursor.insertRow(((x, y), value))

class IDWInterpolation(object):
    def __init__(self):
        self.label = "IDW Interpolation"
        self.description = "Executa interpolação IDW em um shapefile de entrada."

    def getParameterInfo(self):
        return [
            arcpy.Parameter(displayName="Shapefile de Entrada",
                            name="input_shp",
                            datatype="DEFeatureClass",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Pasta de Saída",
                            name="output_folder",
                            datatype="DEFolder",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Cell Size",
                            name="cell_size",
                            datatype="GPDouble",
                            parameterType="Optional",
                            direction="Input"),
            arcpy.Parameter(displayName="Power",
                            name="power",
                            datatype="GPDouble",
                            parameterType="Optional",
                            direction="Input"),
            arcpy.Parameter(displayName="Layer de Recorte (Opcional)",
                            name="mask_layer",
                            datatype="DEFeatureClass",
                            parameterType="Optional",
                            direction="Input")
        ]

    def execute(self, parameters, messages):
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        cell_size = parameters[2].value if parameters[2].value else 0.01
        power = parameters[3].value if parameters[3].value else 2
        mask_layer = parameters[4].valueAsText

        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        field_name = "F_Sobreviv_Percent"
        fields = [f.name for f in arcpy.ListFields(input_shp)]
        if field_name not in fields:
            arcpy.AddField_management(input_shp, field_name, "DOUBLE")
            with arcpy.da.UpdateCursor(input_shp, ["F_Sobreviv", field_name]) as cursor:
                for row in cursor:
                    row[1] = row[0] * 100
                    cursor.updateRow(row)

        arcpy.MakeFeatureLayer_management(input_shp, "shp_layer")

        # Criar um polígono que envolve todos os pontos (convex hull)
        convex_hull = os.path.join(output_folder, "convex_hull.shp")
        arcpy.MinimumBoundingGeometry_management("shp_layer", convex_hull, "CONVEX_HULL")

        # Criar um buffer em torno do convex hull para garantir um recorte adequado
        buffer_output = os.path.join(output_folder, "buffer.shp")
        arcpy.Buffer_analysis(convex_hull, buffer_output, "5000 Meters")  # Ajuste o tamanho do buffer conforme necessário

        # Definir a máscara a ser usada na interpolação
        mask_layer = buffer_output if not mask_layer else mask_layer

        # Definir a extensão para o shapefile de entrada
        arcpy.env.extent = input_shp  
        arcpy.env.mask = ""  # Garante que a máscara não atrapalhe o IDW

        arcpy.CheckOutExtension("spatial")
        out_raster = arcpy.sa.Idw("shp_layer", field_name, cell_size, power)

        # Aplicar a máscara, se houver
        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        arcpy.CheckInExtension("spatial")

        # Salvar o raster sem recorte para debug
        raster_sem_recorte = os.path.join(output_folder, "IDW_Sem_Recorte.tif")
        out_raster.save(raster_sem_recorte)

        # Criar o Layer a partir do raster gerado (sem a parte de mapa)
        # Apenas salva o raster e não adiciona ao mapa automaticamente

