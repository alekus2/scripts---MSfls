import arcpy
from arcpy import sa

class Toolbox(object):
    def __init__(self):
        self.label = "IDW Interpolation"
        self.alias = "idw_toolbox"
        self.tools = [CustomIDWTool]

class CustomIDWTool(object):
    def __init__(self):
        self.label = "IDW Customizável"
        self.description = ("Ferramenta de interpolação IDW com polígono de recorte obrigatório "
                            "e parâmetros simplificados.")
        self.canRunInBackground = False

    def getParameterInfo(self):
        p0 = arcpy.Parameter(
            displayName="Pontos de Entrada",
            name="in_points",
            datatype="GPFeatureLayer",
            parameterType="Required",
            direction="Input")
            
        p1 = arcpy.Parameter(
            displayName="Campo Z",
            name="z_field",
            datatype="Field",
            parameterType="Required",
            direction="Input")
        p1.parameterDependencies = [p0.name]
        
        p2 = arcpy.Parameter(
            displayName="Raster de Saída",
            name="out_raster",
            datatype="DERasterDataset",
            parameterType="Required",
            direction="Output")
        
        p3 = arcpy.Parameter(
            displayName="Polígono de Recorte",
            name="clip_polygon",
            datatype="GPFeatureLayer",
            parameterType="Required",
            direction="Input")

        params = [p0, p1, p2, p3]
        return params

    def execute(self, parameters, messages):
        in_points = parameters[0].valueAsText
        z_field = parameters[1].valueAsText
        out_raster = parameters[2].valueAsText
        clip_polygon = parameters[3].valueAsText

        extent = arcpy.Describe(clip_polygon).extent
        width = extent.XMax - extent.XMin
        height = extent.YMax - extent.YMin
        
        cell_size = min(width, height) / 220

        arcpy.env.extent = extent
	arcpy.env.overwriteOutput = True
        arcpy.env.cellSize = cell_size

        try:
            from arcpy.sa import Idw
            idw_result = Idw(in_points, z_field, cell_size)
            idw_result.save(out_raster)
            
            clipped_raster = arcpy.sa.ExtractByMask(out_raster, clip_polygon)
            clipped_raster.save(out_raster) 
            
        except Exception as e:
            raise e
        return
