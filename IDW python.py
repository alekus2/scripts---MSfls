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

    def execute(self, parameters, messages=None):
        """Executa a interpolação IDW com recorte e gera um PNG compatível."""

        # Recebendo os parâmetros
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText

        # Ativar licença de extensão Spatial Analyst
        arcpy.CheckOutExtension("Spatial")

        # Criando uma camada de feição temporária
        shp_layer = "shp_layer"
        arcpy.MakeFeatureLayer_management(input_shp, shp_layer)

        # Executando a interpolação IDW
        field_name = "F_Sobreviv"  # Alterar para o campo correto do shapefile
        out_raster = Idw(shp_layer, field_name, cell_size, power)

        # Aplicação da máscara (recorte) se especificado
        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        # Criando pasta de saída se não existir
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        # Salvando o raster IDW
        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        # **Conversão para PNG corrigida**
        png_output_path = os.path.join(output_folder, "IDW_Interpolacao.png")

        # Converter para 8 bits antes de salvar como PNG
        temp_raster = os.path.join(output_folder, "IDW_Interpolacao_8bit.tif")
        arcpy.management.CopyRaster(raster_output_path, temp_raster, pixel_type="8_BIT_UNSIGNED")
        arcpy.management.CopyRaster(temp_raster, png_output_path, pixel_type="8_BIT_UNSIGNED", format="PNG")

        # Remover temporário
        arcpy.Delete_management(temp_raster)

        # Liberar a extensão Spatial Analyst
        arcpy.CheckInExtension("Spatial")
