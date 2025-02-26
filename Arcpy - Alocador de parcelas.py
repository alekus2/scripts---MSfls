import arcpy
import os
import pandas as pd

class Toolbox(object):
    def __init__(self):
        """Adiciona a base de programação em"""
        self.label = "Alocador de parcelas."
        self.alias = "alocator_toolbox"
        self.tools = [AlocadorDeParcelas]

class AlocadorDeParcelas(object):
    def __init__(self):
        """Define a ferramenta."""
        self.label = "Alocar parcelas"
        self.description = "Verifica dentro da Base de dados, conta CD_USO_SOL e faz um query e exporta o query como um shp file"
        self.canRunInBackground = False

    def getParameterInfo(self):
        """Define os parâmetros da ferramenta."""
        param_shapefile = arcpy.Parameter(
            displayName="Adicione a sua programação aqui",
            name="base_path",
            datatype="xlss",
            parameterType="Required",
            direction="Input"
        )

        return [param_shapefile]

    def execute(self, parameters, messages):
        """Executa o processamento."""
        base_path = parameters[0].valueAsText

        if not arcpy.Exists(base_path):
            arcpy.AddError(f"Erro: O arquivo do excel {base_path} não foi encontrado.")
            return
        df = pd.read_excel(base_path)
        colunas_esperadas = ['CD_USO_SOL','AREA_HA']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                arcpy.AddError(f"Erro: A coluna {coluna} não foi encontrada no arquivo do excel.")
                return
 
        cod_talhao = df['CD_USO_SOL'](int)
        area_talhao = df['AREA_HA'](float)

        arcpy.AddMessage("")
