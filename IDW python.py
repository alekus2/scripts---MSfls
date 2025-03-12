def execute(self, parameters, messages):
    in_points = parameters[0].valueAsText
    z_field = parameters[1].valueAsText
    out_raster = parameters[2].valueAsText
    power = parameters[4].value if parameters[4].value is not None else 2
    search_type = parameters[5].valueAsText
    barrier = parameters[10].valueAsText if parameters[10].value else ""
    clip_polygon = parameters[11].valueAsText if parameters[11].value else ""

    # Definir a extensão e o tamanho de célula com base no polígono de recorte, se fornecido
    if clip_polygon:
        extent = arcpy.Describe(clip_polygon).extent
        arcpy.env.extent = extent
        cell_size = min(extent.width, extent.height) / 100  # Ajuste conforme necessário
    else:
        extent = arcpy.Describe(in_points).extent
        arcpy.env.extent = extent
        cell_size = min(extent.width, extent.height) / 100  # Ajuste conforme necessário

    arcpy.env.cellSize = cell_size

    if search_type == "Variable":
        num_points = parameters[6].value if parameters[6].value is not None else 12
        max_distance = parameters[7].value if parameters[7].value is not None else ""
        radius_param = f"{num_points};{max_distance}" if max_distance else f"{num_points}"
    else:  # Fixed
        fixed_radius = parameters[8].value if parameters[8].value is not None else ""
        min_points = parameters[9].value if parameters[9].value is not None else ""
        radius_param = f"{fixed_radius};{min_points}" if fixed_radius and min_points else f"{fixed_radius}"

    try:
        from arcpy.sa import Idw, ExtractByMask
        idw_result = Idw(in_points, z_field, cell_size, power, radius_param, barrier)
        
        if clip_polygon:
            idw_result = ExtractByMask(idw_result, clip_polygon)
        
        idw_result.save(out_raster)
        
    except Exception as e:
        raise e
    return
