Traceback (most recent call last):
  File "<string>", line 70, in execute
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\management.py", line 23032, in CreateFishnet
    raise e
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\management.py", line 23029, in CreateFishnet
    retval = convertArcObjectToPythonObject(gp.CreateFishnet_management(*gp_fixargs((out_feature_class, origin_coord, y_axis_coord, cell_width, cell_height, number_rows, number_columns, corner_coord, labels, template, geometry_type), True)))
  File "C:\Program Files\ArcGIS\Pro\Resources\ArcPy\arcpy\geoprocessing\_base.py", line 512, in <lambda>
    return lambda *args: val(*gp_fixargs(args, True))
RuntimeError: Object: Error in executing tool
Failed to execute (AlocadorDeParcelas).
