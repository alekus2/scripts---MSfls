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

        # Verificação de campos obrigatórios no shapefile
        field_names = [f.name for f in arcpy.ListFields(input_shp)]
        required_fields = ["Name", "Parcela", "F_Sobreviv"]

        missing_fields = [field for field in required_fields if field not in field_names]
        if missing_fields:
            arcpy.AddError(f"Faltando campos obrigatórios: {', '.join(missing_fields)}")
            raise

        try:
            # Criação da camada de feição
            arcpy.MakeFeatureLayer_management(input_shp, "shp_layer")
        except Exception as e:
            arcpy.AddError(f"Erro ao criar a camada de feição: {str(e)}")
            raise

        # Verificar a disponibilidade da extensão espacial
        if arcpy.CheckExtension("spatial") == "Available":
            arcpy.CheckOutExtension("spatial")
        else:
            arcpy.AddError("A extensão espacial não está disponível.")
            raise

        try:
            # Executando a interpolação IDW
            out_raster = arcpy.sa.Idw("shp_layer", "F_Sobreviv", cell_size, power)
        except Exception as e:
            arcpy.AddError(f"Erro ao executar a interpolação IDW: {str(e)}")
            raise

        # Verificação de validade do arquivo de máscara
        if mask_layer:
            if not arcpy.Exists(mask_layer):
                arcpy.AddError(f"O arquivo de máscara {mask_layer} não existe.")
                raise
            out_raster = ExtractByMask(out_raster, mask_layer)

        # Verificação da pasta de saída
        if not os.path.exists(output_folder):
            arcpy.AddError(f"A pasta de saída {output_folder} não existe.")
            raise

        raster_output_path = os.path.join(output_folder, "IDW_Interpolacao.tif")
        out_raster.save(raster_output_path)

        try:
            # Criar simbologia diretamente no raster
            arcpy.env.overwriteOutput = True
            symbology = arcpy.mapping.ListLayers(raster_output_path)[0]
            symbology.symbologyType = "STRETCHED"
            symbology.colorRamp = "Yellow to Red"
            arcpy.RefreshActiveView()
        except Exception as e:
            arcpy.AddError(f"Erro ao aplicar simbologia: {str(e)}")
            raise

        # Liberar a extensão espacial
        arcpy.CheckInExtension("spatial")
