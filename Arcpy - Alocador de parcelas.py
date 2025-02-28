Traceback (most recent call last):
  File "<string>", line 66, in execute
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\management.py", line 10316, in MakeFeatureLayer
    raise e
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\management.py", line 10313, in MakeFeatureLayer
    retval = convertArcObjectToPythonObject(gp.MakeFeatureLayer_management(*gp_fixargs((in_features, out_layer, where_clause, workspace, field_info), True)))
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\geoprocessing\_base.py", line 512, in <lambda>
    return lambda *args: val(*gp_fixargs(args, True))
arcgisscripting.ExecuteError:  ERROR 000358: Invalid expression
Failed to execute (MakeFeatureLayer).
