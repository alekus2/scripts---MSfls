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
        """Executa a interpolação IDW com conversão de valores para porcentagem."""

        # Recebendo os parâmetros
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText

        # Ativar licença de extensão Spatial Analyst
        arcpy.CheckOutExtension("Spatial")

        # Criando camada de feição temporária
        shp_layer = "shp_layer"
        arcpy.MakeFeatureLayer_management(input_shp, shp_layer)

        # Verificar se o campo F_Sobreviv existe
        field_name = "F_Sobreviv"
        field_list = [f.name for f in arcpy.ListFields(input_shp)]
        if field_name not in field_list:
            raise Exception(f"O campo '{field_name}' não foi encontrado no Shapefile.")

        # Criar campo temporário para armazenar os valores em porcentagem
        percent_field = "F_Sobreviv_Percent"

        # Se o campo já existir, removê-lo
        if percent_field in field_list:
            arcpy.DeleteField_management(input_shp, percent_field)

        # Criar o novo campo como Double
        arcpy.AddField_management(input_shp, percent_field, "DOUBLE")

        # Atualizar os valores para porcentagem
        with arcpy.da.UpdateCursor(input_shp, [field_name, percent_field]) as cursor:
            for row in cursor:
                row[1] = row[0] * 100  # Convertendo para porcentagem
                cursor.updateRow(row)

        # **Verificar e reprojetar o mask_layer, se necessário**
        if mask_layer:
            shp_sr = arcpy.Describe(input_shp).spatialReference
            mask_sr = arcpy.Describe(mask_layer).spatialReference
            if shp_sr.name != mask_sr.name:
                mask_layer_reprojected = os.path.join(output_folder, "mask_reprojected.shp")
                arcpy.Project_management(mask_layer, mask_layer_reprojected, shp_sr)
                mask_layer = mask_layer_reprojected

        # **Executando IDW usando o campo convertido**
        out_raster = Idw(shp_layer, percent_field, cell_size, power)

        # **Aplicando máscara (recorte)**
        if mask_layer:
            out_raster = ExtractByMask(out_raster, mask_layer)

        # Criando pasta de saída se não existir
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

        # Salvando o raster IDW
        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        # **Conversão para PNG**
        png_output_path = os.path.join(output_folder, "IDW_Interpolacao.png")

        # Converter para 8 bits antes de salvar como PNG
        temp_raster = os.path.join(output_folder, "IDW_Interpolacao_8bit.tif")
        arcpy.management.CopyRaster(raster_output_path, temp_raster, pixel_type="8_BIT_UNSIGNED")
        arcpy.management.CopyRaster(temp_raster, png_output_path, pixel_type="8_BIT_UNSIGNED", format="PNG")

        # Remover temporário
        arcpy.Delete_management(temp_raster)

        # **Remover o campo temporário do shapefile**
        arcpy.DeleteField_management(input_shp, percent_field)

        # Liberar a extensão Spatial Analyst
        arcpy.CheckInExtension("Spatial")
