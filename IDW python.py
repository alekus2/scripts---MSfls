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
        
        if not arcpy.Exists(input_shp):
            messages.addErrorMessage(f"Erro: O Shapefile '{input_shp}' não foi encontrado.")
            return

        field_names = [f.name for f in arcpy.ListFields(input_shp)]
        required_fields = ["Name", "Parcela", "F_Sobreviv"]

        for field in required_fields:
            if field not in field_names:
                messages.addErrorMessage(f"Erro: A coluna '{field}' não foi encontrada no shapefile.")
                return
        
        # Cria uma camada a partir do shapefile de entrada
        arcpy.MakeFeatureLayer_management(input_shp, "shp_layer")

        if arcpy.CheckExtension("spatial") == "Available":
            arcpy.CheckOutExtension("spatial")
        else:
            messages.addErrorMessage("Erro: Extensão do Spatial Analyst não disponível.")
            return

        # Cria a pasta de saída, se não existir
        raster_output_folder = os.path.join(output_folder, "Rasters")
        if not os.path.exists(raster_output_folder):
            os.makedirs(raster_output_folder)

        try:
            print("Executando interpolação IDW...")
            out_raster = arcpy.sa.Idw("shp_layer", "F_Sobreviv", cell_size, power)
    
            if mask_layer:
                print("Aplicando máscara de recorte...")
                out_raster = ExtractByMask(out_raster, mask_layer)
                
            raster_output_path = os.path.join(raster_output_folder, "IDW_Interpolacao.tif")
            out_raster.save(raster_output_path)
            print(f"Raster salvo em {raster_output_path}")

        except Exception as e:
            messages.addErrorMessage(f"Erro ao executar IDW: {str(e)}")

        finally:
            arcpy.CheckInExtension("spatial")
            print("Extensão Spatial Analyst liberada.")

        messages.addMessage("Processamento concluído com sucesso.")