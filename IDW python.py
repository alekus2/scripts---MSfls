import arcpy
from arcpy import sa

class CustomIDWTool(object):
    def __init__(self):
        self.label = "IDW Customizável"
        self.description = ("Ferramenta de interpolação IDW com polígono de recorte obrigatório "
                            "e parâmetros simplificados.")
        self.canRunInBackground = False

    def getParameterInfo(self):
        # 0 - Input Point Features
        p0 = arcpy.Parameter(
            displayName="Pontos de Entrada",
            name="in_points",
            datatype="GPFeatureLayer",
            parameterType="Required",
            direction="Input")
            
        # 1 - Z Value Field
        p1 = arcpy.Parameter(
            displayName="Campo Z",
            name="z_field",
            datatype="Field",
            parameterType="Required",
            direction="Input")
        p1.parameterDependencies = [p0.name]
        
        # 2 - Output Raster
        p2 = arcpy.Parameter(
            displayName="Raster de Saída",
            name="out_raster",
            datatype="DERasterDataset",
            parameterType="Required",
            direction="Output")
        
        # 3 - Polígono de Recorte (obrigatório)
        p3 = arcpy.Parameter(
            displayName="Polígono de Recorte",
            name="clip_polygon",
            datatype="GPFeatureLayer",
            parameterType="Required",
            direction="Input")

        params = [p0, p1, p2, p3]
        return params

    def updateParameters(self, parameters):
        # Não há parâmetros dependentes nesta versão simplificada
        return

    def updateMessages(self, parameters):
        # Sem mensagens para compatibilidade com ArcMap
        return

    def execute(self, parameters, messages):
        in_points = parameters[0].valueAsText
        z_field = parameters[1].valueAsText
        out_raster = parameters[2].valueAsText
        clip_polygon = parameters[3].valueAsText

        # Calcular a extensão do polígono de recorte
        extent = arcpy.Describe(clip_polygon).extent
        width = extent.XMax - extent.XMin
        height = extent.YMax - extent.YMin
        
        # Definir um tamanho de célula baseado na extensão
        cell_size = min(width, height) / 100  # Ajuste a divisão para a resolução desejada

        # Definir a extensão do raster de saída para igualar a do polígono de recorte
        arcpy.env.extent = extent

        # Definir o tamanho da célula no ambiente
        arcpy.env.cellSize = cell_size

        try:
            from arcpy.sa import Idw
            idw_result = Idw(in_points, z_field, cell_size)
            idw_result.save(out_raster)
            
            # Recortar o raster resultante com o polígono de recorte
            clipped_raster = arcpy.sa.ExtractByMask(out_raster, clip_polygon)
            clipped_raster.save(out_raster)  # Sobrescrever o raster de saída com o recorte
            
        except Exception as e:
            raise e
        return

# Classe da Toolbox
class CustomIDWToolbox(object):
    def __init__(self):
        self.label = "Custom IDW Toolbox"
        self.description = "Toolbox para Interpolação IDW Customizável"
        
    def getToolboxes(self):
        return [CustomIDWTool()]
