import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        self.label = "Interpolation Processing Toolbox"
        self.alias = "idwpython_toolbox"
        self.tools = [IDWTool]

class IDWTool(object):
    def __init__(self):
        self.label = "IDW Toolbox com Shapefile"
        self.description = "Executa interpolação IDW usando um Shapefile como entrada."
        self.canRunInBackground = False

    def getParameterInfo(self):
        params = [
            arcpy.Parameter("Shapefile de Entrada", "input_shp", "DEFeatureClass", "Required", "Input"),
            arcpy.Parameter("Pasta de Saída", "output_folder", "DEFolder", "Required", "Input"),
            arcpy.Parameter("Power", "power", "GPDouble", "Required", "Input"),
            arcpy.Parameter("Cell Size", "cell_size", "GPDouble", "Required", "Input"),
            arcpy.Parameter("Layer de Recorte (Opcional)", "mask_layer", "DEFeatureClass", "Optional", "Input")
        ]
        return params

    def execute(self, parameters, _):
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText
        
        arcpy.MakeFeatureLayer_management(input_shp, "shp_layer_temp")

        arcpy.CheckOutExtension("spatial")

        raster_output_folder = os.path.join(output_folder, "Rasters")
        os.makedirs(raster_output_folder, exist_ok=True)

        out_raster = Idw("shp_layer_temp", "F_Sobreviv", cell_size, power)

        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        out_raster.save(os.path.join(raster_output_folder, "IDW_Interpolacao.tif"))

        arcpy.CheckInExtension("spatial")
