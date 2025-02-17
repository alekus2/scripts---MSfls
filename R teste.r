import arcpy
import os
import matplotlib.pyplot as plt

class Toolbox(object):
    def __init__(self):
        """Define a toolbox."""
        self.label = "Shapefile Processing Toolbox"
        self.alias = "shapefile_toolbox"
        self.tools = [ProcessShapefile]

class ProcessShapefile(object):
    def __init__(self):
        """Define a ferramenta."""
        self.label = "Processar Shapefile"
        self.description = "Abre, verifica e processa um shapefile dentro do ArcGIS Pro."
        self.canRunInBackground = False

    def getParameterInfo(self):
        """Define os parâmetros da ferramenta."""
        param_shapefile = arcpy.Parameter(
            displayName="Shapefile de Entrada",
            name="shapefile_path",
            datatype="DEFeatureClass",
            parameterType="Required",
            direction="Input"
        )

        return [param_shapefile]

    def execute(self, parameters, messages):
        """Executa o processamento."""
        shapefile_path = parameters[0].valueAsText

        # Verifica se o arquivo existe
        if not arcpy.Exists(shapefile_path):
            arcpy.AddError(f"Erro: O shapefile {shapefile_path} não foi encontrado.")
            return

        # Abre o shapefile como FeatureClass
        fields = ["Shape", "POINT_X", "POINT_Y"]
        with arcpy.da.SearchCursor(shapefile_path, fields) as cursor:
            data = [row for row in cursor]

        if not data:
            arcpy.AddError("Erro: O shapefile está vazio ou não contém os campos necessários.")
            return

        # Verifica se há colunas necessárias
        field_names = [f.name for f in arcpy.ListFields(shapefile_path)]
        if not all(field in field_names for field in ["POINT_X", "POINT_Y"]):
            arcpy.AddError("Erro: As colunas 'POINT_X' e 'POINT_Y' não foram encontradas.")
            return

        # Filtra dados inválidos (exemplo: valores nulos)
        valid_data = [(x, y) for _, x, y in data if x is not None and y is not None]

        if not valid_data:
            arcpy.AddError("Erro: Nenhum dado válido encontrado após filtragem.")
            return

        # Plotando os pontos
        x_vals, y_vals = zip(*valid_data)
        plt.scatter(x_vals, y_vals, c="blue", label="Pontos")
        plt.xlabel("Longitude")
        plt.ylabel("Latitude")
        plt.title("Pontos do Shapefile")
        plt.legend()
        plt.show()

        # Atualizando os dados no ArcGIS (aqui apenas um exemplo de operação)
        arcpy.AddMessage(f"Processamento concluído. {len(valid_data)} pontos válidos encontrados.")

