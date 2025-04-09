import arcpy
import os

class Toolbox(object):
    def __init__(self):
        self.label = "Excluidor de parcelas"
        self.alias = "exclution_toolbox"
        self.tools = [ExclusaoDeParcelas]

class ExclusaoDeParcelas(object):
    def __init__(self):
        self.label = "Exclusao de parcelas."
        self.description = "Filtra e exclui com base em uns e zeros dentro do talhao."
        self.canRunInBackground = False

    def getParameterInfo(self):
        param_layer = arcpy.Parameter(
            displayName="Camada base de dados",
            name="input_layer",
            datatype="DEFeatureClass",
            parameterType="Required",
            direction="Input"
        )
        param_workspace = arcpy.Parameter(
            displayName="Pasta de saída",
            name="workspace",
            datatype="DEWorkspace",
            parameterType="Required",
            direction="Input"
        )

       

        return [param_workspace, param_layer]

    def execute(self, parameters):
        input_layer = parameters[0].valueAsText
        workspace = parameters[1].valueAsText

        if not arcpy.Exists(base_path):
            arcpy.AddError(f"Erro: O arquivo {base_path} não foi encontrado.")
            return

        try:

        def calcular_maximo(talhao):
            max_parcelas = {}
            valores = [int(row[1]) for row in arcpy.da.SearchCursor("Nome da sua tabela", ["Index", "nm_parcela"]) if row[0] == talhao]
            max_parcelas[talhao] = max(valores)
            return max_parcelas[talhao]

        calcular_maximo(!Index!)

        def autoIncrement(parcela, count):
            parcela=int(parcela)
            count=int(count)
            if count <= 3:
                return 1
            return 1 if parcela % 2 != 0 else 0

        autoIncrement(!nm_parcela!, !CONTADOR!)

        except Exception as e:
            arcpy.AddError(f"Erro ao processar o arquivo Excel: {e}")
