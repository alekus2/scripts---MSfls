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
        self.description = "Cria a coluna CONTADOR (temporária) com o valor máximo de nm_parcela para cada talhão (campo Index) e exclui as feições cuja lógica determine a remoção."
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
        # Parâmetro para o workspace de saída
        param_workspace = arcpy.Parameter(
            displayName="Pasta de saída (workspace)",
            name="workspace",
            datatype="DEWorkspace",
            parameterType="Required",
            direction="Input"
        )
        return [param_layer, param_workspace]

    def execute(self, parameters, messages):
        # Recupera os parâmetros
        input_layer = parameters[0].valueAsText
        workspace = parameters[1].valueAsText

        # Define o workspace
        arcpy.env.workspace = workspace

        # Verifica se o shapefile existe
        if not arcpy.Exists(input_layer):
            arcpy.AddError(f"Erro: O shapefile {input_layer} não foi encontrado.")
            return

        # Campos obrigatórios
        campo_parcela = "nm_parcela"
        campo_talhao = "Index"  # Campo que identifica o talhão

        # Lista de campos existentes
        campos_existentes = [f.name for f in arcpy.ListFields(input_layer)]
        for campo in [campo_parcela, campo_talhao]:
            if campo not in campos_existentes:
                arcpy.AddError(f"O campo {campo} não existe no shapefile.")
                return

        # Nome do campo que será criado temporariamente
        campo_contador = "CONTADOR"
        contador_criado = False

        # Verifica se o campo CONTADOR existe; se não, cria-o
        if campo_contador not in campos_existentes:
            arcpy.AddMessage(f"O campo {campo_contador} não existe. Será criado temporariamente.")
            try:
                arcpy.AddField_management(input_layer, campo_contador, "LONG")
                contador_criado = True
            except Exception as e:
                arcpy.AddError(f"Erro ao criar o campo {campo_contador}: {e}")
                return

        # Primeiro, calcular o valor máximo de nm_parcela para cada talhão (grupo pelo campo Index)
        talhao_max = {}
        try:
            with arcpy.da.SearchCursor(input_layer, [campo_talhao, campo_parcela]) as cursor:
                for row in cursor:
                    try:
                        talhao = row[0]
                        parcela = int(row[1])
                    except Exception as e:
                        messages.addWarningMessage(f"Erro na conversão dos valores: {e}")
                        continue
                    if talhao not in talhao_max or parcela > talhao_max[talhao]:
                        talhao_max[talhao] = parcela
        except Exception as e:
            arcpy.AddError(f"Erro ao calcular o máximo de nm_parcela por talhão: {e}")
            return

        # Atualiza o campo CONTADOR para todas as feições com o máximo calculado para o respectivo talhão
        try:
            with arcpy.da.UpdateCursor(input_layer, [campo_talhao, campo_contador]) as cursor:
                for row in cursor:
                    talhao = row[0]
                    if talhao in talhao_max:
                        row[1] = talhao_max[talhao]
                    else:
                        row[1] = 0
                    cursor.updateRow(row)
        except Exception as e:
            arcpy.AddError(f"Erro ao atualizar o campo {campo_contador}: {e}")
            return

        # Agora, aplicar a lógica de exclusão:
        # Se o CONTADOR (valor máximo de nm_parcela para o talhão) for maior que 3 e nm_parcela for par, exclui a feição.
        try:
            with arcpy.da.UpdateCursor(input_layer, [campo_parcela, campo_contador]) as cursor:
                for row in cursor:
                    try:
                        parcela = int(row[0])
                        contador_valor = int(row[1])
                    except Exception as e:
                        messages.addWarningMessage(f"Erro na conversão dos valores (nm_parcela={row[0]}, {campo_contador}={row[1]}): {e}")
                        continue
                    if contador_valor > 3 and parcela % 2 == 0:
                        cursor.deleteRow()
            messages.addMessage("Processamento concluído com sucesso.")
        except Exception as e:
            arcpy.AddError(f"Erro ao processar o shapefile: {e}")
            return

        # Remove o campo CONTADOR se ele foi criado temporariamente
        if contador_criado:
            try:
                arcpy.DeleteField_management(input_layer, campo_contador)
                arcpy.AddMessage(f"Campo {campo_contador} removido (temporário).")
            except Exception as e:
                arcpy.AddWarningMessage(f"Não foi possível remover o campo {campo_contador}: {e}")
