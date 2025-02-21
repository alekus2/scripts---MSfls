import arcpy
from arcpy.sa import *
import os

class Toolbox(object):
    def __init__(self):
        """Define a toolbox no ArcMap."""
        self.label = "Interpolation Processing Toolbox"
        self.alias = "idwpython_toolbox"
        self.tools = [IDWTool]

class IDWTool(object):
    def __init__(self):
        """Define a ferramenta dentro da Toolbox."""
        self.label = "IDW Toolbox com Shapefile"
        self.description = "Executa interpolação IDW usando um Shapefile como entrada."
        self.canRunInBackground = False

    def getParameterInfo(self):
        """Define os parâmetros da ferramenta."""
        params = [
            arcpy.Parameter(
                displayName="Shapefile de Entrada",
                name="input_shp",
                datatype="DEFeatureClass",
                parameterType="Required",
                direction="Input"
            ),
            arcpy.Parameter(
                displayName="Pasta de Saída",
                name="output_folder",
                datatype="DEFolder",
                parameterType="Required",
                direction="Input"
            ),
            arcpy.Parameter(
                displayName="Power",
                name="power",
                datatype="GPDouble",
                parameterType="Required",
                direction="Input"
            ),
            arcpy.Parameter(
                displayName="Cell Size",
                name="cell_size",
                datatype="GPDouble",
                parameterType="Required",
                direction="Input"
            ),
            arcpy.Parameter(
                displayName="Layer de Recorte (Opcional)",
                name="mask_layer",
                datatype="DEFeatureClass",
                parameterType="Optional",
                direction="Input"
            )
        ]
        return params

    def execute(self, parameters, _):
        """Executa a interpolação IDW."""
        
        # Obtendo os valores dos parâmetros
        input_shp = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cell_size = parameters[3].value  
        mask_layer = parameters[4].valueAsText
        
        # Verifica se o shapefile existe
        if not arcpy.Exists(input_shp):
            raise ValueError(f"Erro: O Shapefile '{input_shp}' não foi encontrado.")

        # Verifica se os campos necessários estão no shapefile
        field_names = [f.name for f in arcpy.ListFields(input_shp)]
        required_fields = ["F_Sobreviv"]

        for field in required_fields:
            if field not in field_names:
                raise ValueError(f"Erro: A coluna '{field}' não foi encontrada no shapefile.")
        
        # Verifica a extensão do Spatial Analyst
        if arcpy.CheckExtension("spatial") == "Available":
            arcpy.CheckOutExtension("spatial")
        else:
            raise RuntimeError("Erro: Extensão do Spatial Analyst não disponível.")

        # Criar a pasta de saída, se não existir
        raster_output_folder = os.path.join(output_folder, "Rasters")
        os.makedirs(raster_output_folder, exist_ok=True)

        try:
            print("Criando Feature Layer temporária...")
            shp_layer = "shp_layer_temp"
            arcpy.MakeFeatureLayer_management(input_shp, shp_layer)

            print("Executando interpolação IDW...")
            out_raster = Idw(shp_layer, "F_Sobreviv", cell_size, power)

            if mask_layer:
                print("Aplicando máscara de recorte...")
                out_raster = ExtractByMask(out_raster, mask_layer)

            # Salvar o raster resultante
            raster_output_path = os.path.join(raster_output_folder, "IDW_Interpolacao.tif")
            out_raster.save(raster_output_path)
            print(f"Raster salvo em {raster_output_path}")

        except Exception as e:
            raise RuntimeError(f"Erro ao executar IDW: {str(e)}")

        finally:
            # Libera a extensão Spatial Analyst
            arcpy.CheckInExtension("spatial")
            print("Extensão Spatial Analyst liberada.")

        print("Processamento concluído com sucesso.")
