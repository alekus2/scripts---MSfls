import arcpy
from arcpy import sa

class CustomIDWTool(object):
    def __init__(self):
        self.label = "IDW Customizável"
        self.description = ("Ferramenta similar à do ArcMap para interpolação IDW, "
                            "com opções customizáveis para definir a lógica do raio de busca.")
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
        
        # 3 - Output Cell Size (opcional)
        p3 = arcpy.Parameter(
            displayName="Tamanho da Célula",
            name="cell_size",
            datatype="GPDouble",
            parameterType="Optional",
            direction="Input")
        p3.value = 10  # valor padrão; ajuste conforme necessário
        
        # 4 - Power (opcional)
        p4 = arcpy.Parameter(
            displayName="Potência (Power)",
            name="power",
            datatype="GPDouble",
            parameterType="Optional",
            direction="Input")
        p4.value = 2
        
        # 5 - Tipo de Raio de Busca: Fixed ou Variable
        p5 = arcpy.Parameter(
            displayName="Tipo de Raio de Busca",
            name="search_radius_type",
            datatype="GPString",
            parameterType="Required",
            direction="Input")
        p5.filter.list = ["Fixed", "Variable"]
        p5.value = "Variable"
        
        # 6 - Número de Pontos (para raio variável)
        p6 = arcpy.Parameter(
            displayName="Número de Pontos",
            name="num_points",
            datatype="GPLong",
            parameterType="Optional",
            direction="Input")
        p6.value = 12
        
        # 7 - Distância Máxima (para raio variável)
        p7 = arcpy.Parameter(
            displayName="Distância Máxima",
            name="max_distance",
            datatype="GPDouble",
            parameterType="Optional",
            direction="Input")
        p7.value = ""
        
        # 8 - Raio de Busca (para raio fixo)
        p8 = arcpy.Parameter(
            displayName="Raio de Busca",
            name="search_radius",
            datatype="GPDouble",
            parameterType="Optional",
            direction="Input")
        p8.value = ""
        
        # 9 - Número Mínimo de Pontos (para raio fixo)
        p9 = arcpy.Parameter(
            displayName="Número Mínimo de Pontos",
            name="min_points",
            datatype="GPLong",
            parameterType="Optional",
            direction="Input")
        p9.value = 0
        
        # 10 - Barreiras (opcional)
        p10 = arcpy.Parameter(
            displayName="Barreiras (Opcional)",
            name="barrier_features",
            datatype="GPFeatureLayer",
            parameterType="Optional",
            direction="Input")
        
        params = [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10]
        return params

    def updateParameters(self, parameters):
        # Habilita ou desabilita parâmetros conforme o tipo de raio selecionado
        if parameters[5].valueAsText == "Variable":
            parameters[6].enabled = True
            parameters[7].enabled = True
            parameters[8].enabled = False
            parameters[9].enabled = False
        elif parameters[5].valueAsText == "Fixed":
            parameters[6].enabled = False
            parameters[7].enabled = False
            parameters[8].enabled = True
            parameters[9].enabled = True
        else:
            parameters[6].enabled = False
            parameters[7].enabled = False
            parameters[8].enabled = False
            parameters[9].enabled = False
        return

    def updateMessages(self, parameters):
        # Sem mensagens para compatibilidade com ArcMap
        return

    def execute(self, parameters, messages):
        # Recupera os parâmetros
        in_points = parameters[0].valueAsText
        z_field = parameters[1].valueAsText
        out_raster = parameters[2].valueAsText
        cell_size = parameters[3].value if parameters[3].value is not None else ""
        power = parameters[4].value if parameters[4].value is not None else 2
        search_type = parameters[5].valueAsText
        barrier = parameters[10].valueAsText if parameters[10].value else ""

        # Configura o parâmetro do raio de busca
        if search_type == "Variable":
            num_points = parameters[6].value if parameters[6].value is not None else 12
            max_distance = parameters[7].value if parameters[7].value is not None else ""
            if max_distance:
                radius_param = f"{num_points};{max_distance}"
            else:
                radius_param = f"{num_points}"
        else:  # Fixed
            fixed_radius = parameters[8].value if parameters[8].value is not None else ""
            min_points = parameters[9].value if parameters[9].value is not None else ""
            if fixed_radius and min_points:
                radius_param = f"{fixed_radius};{min_points}"
            else:
                radius_param = f"{fixed_radius}"

        # Define o ambiente para o tamanho da célula, se fornecido
        if cell_size:
            arcpy.env.cellSize = cell_size

        try:
            from arcpy.sa import Idw
            idw_result = Idw(in_points, z_field, cell_size, power, radius_param, barrier)
            idw_result.save(out_raster)
        except Exception as e:
            # Sem mensagens, apenas a exceção é levantada
            raise e
        return
