Traceback (most recent call last):
  File "<string>", line 77, in execute
  File "<string>", line 70, in execute
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\sa\Functions.py", line 5385, in Idw
    return Wrapper(
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\sa\Utils.py", line 55, in swapper
    result = wrapper(*args, **kwargs)
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\sa\Functions.py", line 5376, in Wrapper
    result = arcpy.gp.Idw_sa(
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\geoprocessing\_base.py", line 512, in <lambda>
    return lambda *args: val(*gp_fixargs(args, True))
arcgisscripting.ExecuteError: Failed to execute. Parameters are not valid.
ERROR 010340: Snap raster C:\Users\alex_santos4\Documents\ArcGIS\Projects\MyProject\MyProject.gdb\V2_6465_Piraci_CustomIDWTool8 does not exist.
Failed to execute (Idw).


Failed to execute (CustomIDWTool).
