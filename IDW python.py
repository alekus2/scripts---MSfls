def execute(self, parameters, messages):
    in_points = parameters[0].valueAsText
    z_field = parameters[1].valueAsText
    out_raster = parameters[2].valueAsText
    power = parameters[4].value if parameters[4].value is not None else 2
    search_type = parameters[5].valueAsText
    barrier = parameters[10].valueAsText if parameters[10].value else ""

    # Calcular a extensão do conjunto de dados de entrada
    extent = arcpy.Describe(in_points).extent
    width = extent.XMax - extent.XMin
    height = extent.YMax - extent.YMin
    
    # Definir um tamanho de célula baseado na extensão, ajustável conforme necessário
    cell_size = min(width, height) / 100  # Ajuste a divisão para a resolução desejada

    # Definir a extensão do raster de saída para igualar a do conjunto de dados de entrada
    arcpy.env.extent = extent

    # Definir o tamanho da célula no ambiente
    arcpy.env.cellSize = cell_size

    if search_type == "Variable":
        num_points = parameters[6].value if parameters[6].value is not None else 12
        max_distance = parameters[7].value if parameters[7].value is not None else ""
        if max_distance:
            radius_param = "{};{}".format(num_points, max_distance)
        else:
            radius_param = "{}".format(num_points)
    else:  # Fixed
        fixed_radius = parameters[8].value if parameters[8].value is not None else ""
        min_points = parameters[9].value if parameters[9].value is not None else ""
        if fixed_radius and min_points:
            radius_param = "{};{}".format(fixed_radius, min_points)
        else:
            radius_param = "{}".format(fixed_radius)

    try:
        from arcpy.sa import Idw
        idw_result = Idw(in_points, z_field, cell_size, power, radius_param, barrier)
        idw_result.save(out_raster)
    except Exception as e:
        raise e
    return