import arcpy
from arcpy.sa import *
import os
import pandas as pd

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
                            direction="Input"),
            arcpy.Parameter(displayName="Power",
                            name="power",
                            datatype="GPDouble",
                            parameterType="Required",
                            direction="Input"),
            arcpy.Parameter(displayName="Cell Size",
                            name="cell_size",
                            datatype="GPDouble",
                            parameterType="Required",
                            direction="Input")
        ]
        return params

    def execute(self, parameters, messages):
        csv_file = parameters[0].valueAsText
        output_folder = parameters[1].valueAsText
        power = parameters[2].value
        cellSize = parameters[3].value  

        if not os.path.exists(csv_file):
            raise FileNotFoundError(f"Erro: O arquivo '{csv_file}' não foi encontrado.")

        df = pd.read_csv(csv_file) 

        colunas_esperadas = ['Name', 'Parcela', 'F_Sobreviv']
        for coluna in colunas_esperadas:
            if coluna not in df.columns:
                raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo.")

        df['F_Sobreviv'] = df['F_Sobreviv'].fillna(0) * 100

        barrier = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/WetlandBarrier/"
        rhaPoints = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/RHA_Waypoints"
        habitatData = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/habitatDetails"
        rasterPath = os.path.join(output_folder, "Rasters")
        
        rhaField = "IDENT"
        habitatField = "PointName"
        rhaUnit = "ModelUnit"
        barrierUnit = "ModelUnit"
        unitList = [1, 2, 3, 4, 5, 6, 7, 8]

        try:
            print("Juntando waypoints com dados de habitat...")
            arcpy.MakeFeatureLayer_management(rhaPoints, "rhaLyr")
            arcpy.AddJoin_management("rhaLyr", rhaField, habitatData, habitatField)
        except Exception as e:
            messages.addErrorMessage(f"Erro ao juntar dados: {str(e)}")
            return

        print("Criando lista de campos de vegetação para modelagem IDW...")
        fieldList = [field.name for field in arcpy.ListFields(habitatData)]
        fList = fieldList[2:17]

        try:
            if arcpy.CheckExtension("spatial") == "Available":
                arcpy.CheckOutExtension("spatial")
                print("Licença do Spatial Analyst verificada.")
            else:
                raise Exception("Extensão do Spatial Analyst não disponível.")
        except Exception as e:
            messages.addErrorMessage(f"Erro ao verificar a licença: {str(e)}")
            return

        for unit in unitList:
            print(f"Criando cláusula where para a unidade de estudo {unit}...")
            whereRHA = f"[{rhaUnit}] = '{unit}'"
            whereBarrier = f"[{barrierUnit}] = '{unit}'"

            arcpy.MakeFeatureLayer_management("rhaLyr", "currentRHA", whereRHA)
            arcpy.MakeFeatureLayer_management(barrier, "currentBarrier", whereBarrier)

            for feat in fList:
                try:
                    print(f"Executando modelo IDW para {feat}...")
                    outRaster = arcpy.sa.Idw("currentRHA", f"habitatDetails.{feat}", cellSize, power, "", "currentBarrier")
                    rasterOutputPath = os.path.join(rasterPath, f"{feat}_{unit}.tif")
                    outRaster.save(rasterOutputPath)
                    print(f"IDW executado com sucesso para {feat}.")
                    
                    # Adiciona o raster ao mapa e exporta
                    mxd = arcpy.mapping.MapDocument("CURRENT")
                    df = arcpy.mapping.ListDataFrames(mxd, "Layers")[0]
                    newLayer = arcpy.mapping.Layer(rasterOutputPath)
                    arcpy.mapping.AddLayer(df, newLayer)
                    arcpy.mapping.ExportToPNG(mxd, os.path.join(output_folder, f"{feat}_{unit}.png"))

                except Exception as e:
                    print(f"{feat} falhou na interpolação: {str(e)}")

            arcpy.Delete_management("currentRHA")
            arcpy.Delete_management("currentBarrier")

        arcpy.CheckInExtension("spatial")
        print("Licença do Spatial verificada novamente.")

        messages.addMessage("Processamento concluído com sucesso.")