import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        self.label = "IDW Interpolation"
        self.alias = "idw_toolbox"
        self.tools = [IDWInterpolation]

class IDWInterpolation(object):
    def __init__(self):
        self.label = "IDW Interpolation Tool"
        self.description = "Realiza interpolação IDW com base em um shapefile de entrada e gera um mapa de calor."

    def getParameterInfo(self):
        return [
            arcpy.Parameter(displayName="Pasta de Saída",
                            name="output_folder",
                            datatype="DEFolder",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Shapefile de Entrada",
                            name="input_shapefile",
                            datatype="DEFeatureClass",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Layer de Recorte",
                            name="clip_feature",
                            datatype="DEFeatureClass",
                            parameterType="Required",
                            direction="Input")
        ]

    def execute(self, parameters, messages):
        output_folder = parameters[0].valueAsText
        input_shapefile = parameters[1].valueAsText
        clip_feature = parameters[2].valueAsText

        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        if arcpy.CheckExtension("Spatial") != "Available":
            messages.addErrorMessage("Extensão Spatial Analyst não disponível.")
            return
        arcpy.CheckOutExtension("Spatial")

        arcpy.env.workspace = output_folder
        arcpy.env.overwriteOutput = True
        arcpy.env.cellSize = 30  

        if not arcpy.Exists(input_shapefile):
            messages.addErrorMessage(f"O shapefile de entrada '{input_shapefile}' não existe.")
            return

        if not arcpy.Exists(clip_feature):
            messages.addErrorMessage(f"O layer de recorte '{clip_feature}' não existe.")
            return

        field_name = "F_Percent"
        field_names = [f.name for f in arcpy.ListFields(input_shapefile)]
        if field_name not in field_names:
            messages.addErrorMessage(f"O campo '{field_name}' não foi encontrado no shapefile.")
            return

        valores = []
        with arcpy.da.SearchCursor(input_shapefile, [field_name]) as cursor:
            for row in cursor:
                valores.append(row[0])

        if not valores:
            messages.addErrorMessage(f"O campo '{field_name}' não contém valores válidos.")
            return

        shp_layer = "shp_layer"
        arcpy.MakeFeatureLayer_management(input_shapefile, shp_layer)

        try:
            search_radius = RadiusVariable(12)
            out_raster = Idw(shp_layer, field_name, arcpy.env.cellSize, 2, search_radius)
            out_raster = ExtractByMask(out_raster, clip_feature)

            arcpy.MakeRasterLayer_management(out_raster, "IDW_Raster_Layer")

            raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
            out_raster.save(raster_output_path)
            messages.addMessage(f"Raster salvo em: {raster_output_path}")

        except Exception as e:
            messages.addErrorMessage(f"Erro na interpolação IDW: {str(e)}")
        
        finally:
            arcpy.CheckInExtension("Spatial")
