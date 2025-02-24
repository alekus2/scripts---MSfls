import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        self.label = "Interpolation Processing Toolbox"
        self.alias = "idwpython_toolbox"
        self.tools = [IDWToolbox]

class IDWToolbox(object):
    def __init__(self):
        self.label = "IDW Toolbox"
        self.description = "Executa interpolação IDW considerando todas as parcelas."

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
        return params

    def execute(self, parameters, messages):
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        cell_size = parameters[2].value if parameters[2].value else 10
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

        arcpy.CheckOutExtension("spatial")

        out_raster = arcpy.sa.Idw("shp_layer", field_name, cell_size, power)

        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        arcpy.CheckInExtension("spatial")
