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

    def execute(self, parameters):
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText

        # Criação da camada de feição
        arcpy.MakeFeatureLayer_management(input_shp, "shp_layer")

        # Verificar a disponibilidade da extensão espacial
        arcpy.CheckOutExtension("spatial")

        # Executando a interpolação IDW
        out_raster = arcpy.sa.Idw("shp_layer", "F_Sobreviv", cell_size, power)

        # Aplicação da máscara, se houver
        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        # Verificação da pasta de saída
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        # Criar simbologia diretamente no raster
        arcpy.env.overwriteOutput = True
        symbology = arcpy.mapping.ListLayers(raster_output_path)[0]
        symbology.symbologyType = "STRETCHED"
        symbology.colorRamp = "Yellow to Red"
        arcpy.RefreshActiveView()

        # Liberar a extensão espacial
        arcpy.CheckInExtension("spatial")
