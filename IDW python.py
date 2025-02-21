import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        """Define a toolbox."""
        self.label = "Interpolation Processing Toolbox"
        self.alias = "idwpython_toolbox"
        self.tools = [IDWToolbox]

class IDWToolbox(object):
    def __init__(self):
        self.label = "IDW Toolbox com Shapefile"
        self.description = "Executa interpolação IDW usando um Shapefile como entrada."

    def getParameterInfo(self):
        params = [
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
            arcpy.Parameter(displayName="Power",
                            name="power",
                            datatype="GPDouble",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Cell Size",
                            name="cell_size",
                            datatype="GPDouble",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Layer de Recorte (Opcional)",
                            name="mask_layer",
                            datatype="DEFeatureClass",
                            parameterType="Optional",
                            direction="Input")
        ]
        return params

    def execute(self, parameters, messages):
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText

        field_names = [f.name for f in arcpy.ListFields(input_shp)]
        required_fields = ["Name", "Parcela", "F_Sobreviv"]

        arcpy.MakeFeatureLayer_management(input_shp, "shp_layer")

        arcpy.CheckOutExtension("spatial")

        raster_output_folder = os.path.join(output_folder, "Rasters")
        if not os.path.exists(raster_output_folder):
            os.makedirs(raster_output_folder)

        out_raster = arcpy.sa.Idw("shp_layer", "F_Sobreviv", cell_size, power)
    
        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)
                
        raster_output_path = os.path.join(raster_output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        symbology = arcpy.sa.RasterClassifySymbology()
        symbology.valueField = "Value"
        symbology.breakCount = 5
        symbology.colorRamp = "Yellow to Red"

        arcpy.ApplySymbologyFromRasterClassify(out_raster, symbology)

        arcpy.CheckInExtension("spatial")
