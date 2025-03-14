import arcpy
from arcpy import sa

class Toolbox(object):
    def __init__(self):
        self.label = "IDW Interpolation"
        self.alias = "idw_toolbox"
        self.tools = [CustomIDWTool()]

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

    def execute(self, parameters):
        in_points = parameters[0].valueAsText
        z_field = parameters[1].valueAsText
        out_raster = parameters[2].valueAsText
        clip_polygon = parameters[3].valueAsText

        extent = arcpy.Describe(clip_polygon).extent
        width = extent.XMax - extent.XMin
        height = extent.YMax - extent.YMin
        
        cell_size = min(width, height) / 220

        arcpy.env.extent = extent
        arcpy.env.cellSize = cell_size

        spatial_ref_points = arcpy.Describe(in_points).spatialReference
        spatial_ref_clip = arcpy.Describe(clip_polygon).spatialReference

        if spatial_ref_points.name != spatial_ref_clip.name:
            in_points_temp = "in_memory/in_points_reprojected"
            arcpy.Project_management(in_points, in_points_temp, spatial_ref_clip)
            in_points = in_points_temp

        idw_result = sa.Idw(in_points, z_field, cell_size)
        idw_result.save(out_raster)
        
        clipped_raster = sa.ExtractByMask(out_raster, clip_polygon)
        clipped_raster.save(out_raster)

        if 'in_points_temp' in locals():
            arcpy.Delete_management(in_points_temp)


Executing: CustomIDWTool V2_6465_Piracicaba_T024_30dias F_Sobreviv C:\Users\alex_santos4\Documents\ArcGIS\Default.gdb\V2_6465_Piracicaba_T024_30di USO_DO_SOLO_6465_Piracicaba_T024
Start Time: Fri Mar 14 09:37:38 2025
Running script CustomIDWTool...
TypeError: execute() takes exactly 2 arguments (3 given)
Failed to execute (CustomIDWTool).
Failed at Fri Mar 14 09:37:38 2025 (Elapsed Time: 0,05 seconds)
WARNING 001003: Datum conflict between input and output.
