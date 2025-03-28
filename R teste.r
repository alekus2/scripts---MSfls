import arcpy
import os
from collections import Counter

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
        self.description = "Verifica NM_PARCELA, conta CD_USO_SOL e remove registros pares."
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

        # Verifica se os campos necessários existem
        field_names = [f.name for f in arcpy.ListFields(shapefile_path)]
        if "NM_PARCELA" not in field_names:
            arcpy.AddError("Erro: A coluna 'NM_PARCELA' não foi encontrada no shapefile.")
            return
        if "CD_USO_SOL" not in field_names:
            arcpy.AddError("Erro: A coluna 'CD_USO_SOL' não foi encontrada no shapefile.")
            return

        # Adiciona os campos se não existirem
        if "CONTADOR" not in field_names:
            arcpy.AddField_management(shapefile_path, "CONTADOR", "LONG")
        if "EXCLUIR" not in field_names:
            arcpy.AddField_management(shapefile_path, "EXCLUIR", "SHORT")

        # Dicionário para contar valores repetidos em "CD_USO_SOL"
        uso_sol_counter = Counter()
        nm_parcela_dict = {}

        with arcpy.da.SearchCursor(shapefile_path, ["CD_USO_SOL", "NM_PARCELA"]) as cursor:
            for row in cursor:
                cd_uso_sol, nm_parcela = row
                uso_sol_counter[cd_uso_sol] += 1
                if cd_uso_sol not in nm_parcela_dict:
                    nm_parcela_dict[cd_uso_sol] = []
                nm_parcela_dict[cd_uso_sol].append(nm_parcela)

        # Atualiza os campos CONTADOR e EXCLUIR
        with arcpy.da.UpdateCursor(shapefile_path, ["CD_USO_SOL", "NM_PARCELA", "CONTADOR", "EXCLUIR"]) as cursor:
            for row in cursor:
                cd_uso_sol, nm_parcela = row[0], row[1]
                count_value = uso_sol_counter[cd_uso_sol]

                # Se NM_PARCELA for menor que 3, define contador como 1
                if nm_parcela < 3:
                    count_value = 1

                excluir_value = 1 if count_value % 2 != 0 else 0
                row[2] = count_value  # Atualiza CONTADOR
                row[3] = excluir_value  # Atualiza EXCLUIR
                cursor.updateRow(row)

        # Remove as linhas onde EXCLUIR == 0
        with arcpy.da.UpdateCursor(shapefile_path, ["EXCLUIR"]) as cursor:
            for row in cursor:
                if row[0] == 0:
                    cursor.deleteRow()

        arcpy.AddMessage("Processamento concluído com sucesso. Registros pares foram removidos.")
