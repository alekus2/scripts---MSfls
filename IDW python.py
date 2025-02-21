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
        params = []

        param1 = arcpy.Parameter(
            displayName="Shapefile de Entrada",
            name="input_shp",
            datatype="DEFeatureClass",
            parameterType="Required",
            direction="Input"
        )

        param2 = arcpy.Parameter(
            displayName="Pasta de Saída",
            name="output_folder",
            datatype="DEFolder",
            parameterType="Required",
            direction="Input"
        )

        param3 = arcpy.Parameter(
            displayName="Power",
            name="power",
            datatype="GPDouble",
            parameterType="Required",
            direction="Input"
        )

        param4 = arcpy.Parameter(
            displayName="Cell Size",
            name="cell_size",
            datatype="GPDouble",
            parameterType="Required",
            direction="Input"
        )

        param5 = arcpy.Parameter(
            displayName="Layer de Recorte (Opcional)",
            name="mask_layer",
            datatype="DEFeatureClass",
            parameterType="Optional",
            direction="Input"
        )

        params.extend([param1, param2, param3, param4, param5])
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
