import arcpy
from arcpy.sa import *
import pandas as pd
import os

class IDWToolbox(object):
    def __init__(self):
        self.label = "IDW Toolbox"
        self.description = "Toolbox para executar IDW com dados de entrada em CSV."

    def getParameterInfo(self):
        params = [arcpy.Parameter(displayName="CSV File",
                                   name="csv_file",
                                   datatype="DEFile",
                                   parameterType="Required",
                                   direction="Input"),
                  arcpy.Parameter(displayName="Output Folder",
                                   name="output_folder",
                                   datatype="DEFolder",
                                   parameterType="Required",
                                   direction="Input")]
        return params

    def execute(self, parameters, messages):
        csv_file = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText

        if not os.path.exists(csv_file):
            raise FileNotFoundError(f"Erro: O arquivo '{csv_file}' não foi encontrado.")

        df = pd.read_csv(csv_file)  # Usar pd.read_csv para CSV

        colunas_esperadas = ['Name', 'Parcela', 'F_Sobreviv']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo.")

        # Converter valores da coluna F_Sobreviv em porcentagem
        df['F_Sobreviv'] = df['F_Sobreviv'].fillna(0) * 100

        # Resto do seu código para IDW usando os valores convertidos...
        # Aqui você deve integrar a lógica já apresentada para interpolação IDW

        # Exemplo de como pode ser chamado o IDW
        # (Assegure-se de usar a coluna convertida em porcentagem)
        # ...
        
        # Salvar os resultados na pasta de saída
        # ...

        messages.addMessage("Processamento concluído com sucesso.")

# Para usar a toolbox, você deve salvar este código como um arquivo .pyt e adicioná-lo ao ArcGIS.