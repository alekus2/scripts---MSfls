import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        self.label = "Exemplo de Interpolação IDW"
        self.alias = "idw_example_toolbox"
        self.tools = [IDWInterpolationExample]

class IDWInterpolationExample(object):
    def __init__(self):
        self.label = "Exemplo de Interpolação IDW"
        self.description = "Cria um shapefile fictício, cria um buffer com base nos pontos e realiza a interpolação IDW."

    def getParameterInfo(self):
        return [
            arcpy.Parameter(displayName="Pasta de Saída",
                            name="output_folder",
                            datatype="DEFolder",
                            parameterType="Required",
                            direction="Input")
        ]

    def execute(self, parameters, messages):
        output_folder = parameters[0].valueAsText

        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        if not arcpy.CheckExtension("Spatial"):
            arcpy.CheckOutExtension("Spatial")	
            return
        arcpy.CheckOutExtension("Spatial")

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

        buffer_output = os.path.join(output_folder, "buffer.shp")
        arcpy.Buffer_analysis(shapefile_path, buffer_output, "1000 Meters")

        field_name = "F_Sobreviv"
        arcpy.MakeFeatureLayer_management(shapefile_path, "shp_layer")

        cell_size = 0.01
        power = 30

        out_raster = arcpy.sa.Idw("shp_layer", field_name, cell_size, power)

        out_raster = ExtractByMask(out_raster, buffer_output)

        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        arcpy.CheckInExtension("Spatial")
