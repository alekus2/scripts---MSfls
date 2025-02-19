# Author: Roy Hewitt
# US Fish and Wildlife Service
# December 2011

import arcpy
from arcpy.sa import *
import os

class IDWToolbox(object):
    def __init__(self):
        self.label = "IDW Toolbox"
        self.description = "Toolbox para executar IDW com dados de entrada em CSV."

    def getParameterInfo(self):
        params = [
            arcpy.Parameter(displayName="Arquivo CSV",
                            name="csv_file",
                            datatype="DEFile",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Pasta de Saída",
                            name="output_folder",
                            datatype="DEFolder",
                            parameterType="Required",
                            direction="Input")
        ]
        return params

    def execute(self, parameters, messages):
        csv_file = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText

        # Verifica se o arquivo CSV existe
        if not os.path.exists(csv_file):
            raise FileNotFoundError(f"Erro: O arquivo '{csv_file}' não foi encontrado.")

        # Lê os dados do arquivo CSV
        df = pd.read_csv(csv_file)  # Usar pd.read_csv para CSV

        colunas_esperadas = ['Name', 'Parcela', 'F_Sobreviv']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo.")

        # Converter valores da coluna F_Sobreviv em porcentagem
        df['F_Sobreviv'] = df['F_Sobreviv'].fillna(0) * 100

        # Criação de caminhos de arquivos
        barrier = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/WetlandBarrier/"
        rhaPoints = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/RHA_Waypoints"
        habitatData = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/habitatDetails"
        rasterPath = os.path.join(output_folder, "Rasters")
        
        # Criação de variáveis de campo
        rhaField = "IDENT"
        habitatField = "PointName"
        rhaUnit = "ModelUnit"
        barrierUnit = "ModelUnit"

        # Lista de unidades
        unitList = [1, 2, 3, 4, 5, 6, 7, 8]

        # Criar junção entre pontos RHA e tabela de habitat
        try:
            print("Juntando waypoints com dados de habitat...")
            arcpy.MakeFeatureLayer_management(rhaPoints, "rhaLyr")
            arcpy.AddJoin_management("rhaLyr", rhaField, habitatData, habitatField)
        except:
            print(arcpy.GetMessages(0))

        # Criar lista de atributos de vegetação para modelagem IDW
        print("Criando lista de campos de vegetação para modelagem IDW...")
        fieldList = [field.name for field in arcpy.ListFields(habitatData)]
        fList = fieldList[2:17]

        power = 2  # À medida que a distância aumenta, o ponto tem menos impacto na interpolação
        cellSize = 60  # Tamanho da célula raster

        # Checar extensão do Spatial Analyst
        try:
            if arcpy.CheckExtension("spatial") == "Available":
                arcpy.CheckOutExtension("spatial")
                print("Licença do Spatial Analyst verificada.")
        except:
            print("Extensão do Spatial Analyst não disponível.")
            print(arcpy.GetMessages(2))

        # Loop através das unidades
        try:
            for unit in unitList:
                print("Criando cláusula where para a unidade de estudo " + str(unit) + "...")
                whereRHA = '[' + rhaUnit + '] = ' + "'" + str(unit) + "'"
                whereBarrier = '[' + barrierUnit + '] = ' + "'" + str(unit) + "'"

                # Criar camadas de feições para pontos RHA e barreira
                arcpy.MakeFeatureLayer_management("rhaLyr", "currentRHA", whereRHA)
                arcpy.MakeFeatureLayer_management(barrier, "currentBarrier", whereBarrier)

                for feat in fList:
                    try:
                        print("Executando modelo IDW para " + feat + "...")
                        # IDW Analyst
                        outRaster = arcpy.sa.Idw("currentRHA", "habitatDetails." + feat, cellSize, power, "", "currentBarrier")
                        rasterOutputPath = os.path.join(rasterPath, f"{feat}_{unit}.tif")
                        outRaster.save(rasterOutputPath)
                        print("IDW executado com sucesso para " + feat + ".")
                    except:
                        print(feat + " falhou na interpolação.")
                        print(arcpy.GetMessages(2))

                # Deletar camadas de feição
                arcpy.Delete_management("currentRHA")
                arcpy.Delete_management("currentBarrier")
        except:
            print(arcpy.GetMessages(2))
        finally:
            arcpy.CheckInExtension("spatial")
            print("Licença do Spatial verificada novamente.")

        print("Finalizado o módulo IDW.")

# Para usar a toolbox, você deve salvar este código como um arquivo .pyt e adicioná-lo ao ArcGIS.