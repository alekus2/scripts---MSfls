import arcpy
import os

class Toolbox(object):
    def __init__(self):
        self.label = "Excluidor de parcelas"
        self.alias = "exclution_toolbox"
        self.tools = [ExclusaoDeParcelas]

class ExclusaoDeParcelas(object):
    def __init__(self):
        self.label = "Exclusao de parcelas"
        self.description = "Filtra e exclui feições com base em uns e zeros, utilizando a lógica de par e ímpar."
        self.canRunInBackground = False

    def getParameterInfo(self):
        # Parâmetro para o shapefile de entrada
        param_layer = arcpy.Parameter(
            displayName="Shapefile de entrada",
            name="input_layer",
            datatype="DEFeatureClass",
            parameterType="Required",
            direction="Input"
        )
        # Parâmetro para a pasta de saída (workspace)
        param_workspace = arcpy.Parameter(
            displayName="Pasta de saída",
            name="workspace",
            datatype="DEWorkspace",
            parameterType="Required",
            direction="Input"
        )
        return [param_layer, param_workspace]

    def autoIncrement(self, parcela, count):
        """
        Função que define a lógica:
        - Se count <= 3, retorna 1 (mantém a feição);
        - Caso contrário, se parcela for ímpar retorna 1, se for par retorna 0.
        """
        try:
            parcela = int(parcela)
            count = int(count)
        except Exception as e:
            arcpy.AddWarning(f"Erro na conversão dos valores: {e}")
            return None

        if count <= 3:
            return 1
        return 1 if parcela % 2 != 0 else 0

    def execute(self, parameters, messages):
        # Recupera os parâmetros de entrada
        input_layer = parameters[0].valueAsText
        workspace = parameters[1].valueAsText

        # Define o ambiente de workspace
        arcpy.env.workspace = workspace

        # Considera que o shapefile possui os campos "nm_parcela" e "CONTADOR"
        fields = ["nm_parcela", "CONTADOR"]

        try:
            # Usando UpdateCursor para iterar e excluir as feições que retornarem 0 na função autoIncrement
            with arcpy.da.UpdateCursor(input_layer, fields) as cursor:
                for row in cursor:
                    resultado = self.autoIncrement(row[0], row[1])
                    if resultado is None:
                        messages.addWarningMessage(f"Não foi possível processar a feição com parcela: {row[0]}")
                        continue
                    if resultado == 0:
                        cursor.deleteRow()
            messages.addMessage("Processamento concluído com sucesso.")
        except Exception as e:
            arcpy.AddError(f"Erro ao processar o shapefile: {e}")
