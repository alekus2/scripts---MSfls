import arcpy
from arcpy.sa import *
import os
import pandas as pd

def getParameterInfo(self):
    params = [
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

    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"Erro: O arquivo '{csv_file}' não foi encontrado.")

    df = pd.read_csv(csv_file) 

    colunas_esperadas = ['Name', 'Parcela', 'F_Sobreviv']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo.")

    df['F_Sobreviv'] = df['F_Sobreviv'].fillna(0) * 100

    power = parameters[2].value
    cellSize = parameters[3].value  
    
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
    except:
            print(arcpy.GetMessages(0))

    print("Criando lista de campos de vegetação para modelagem IDW...")
    fieldList = [field.name for field in arcpy.ListFields(habitatData)]
    fList = fieldList[2:17]

    power = 2  
    cellSize = 60  

    try:
            if arcpy.CheckExtension("spatial") == "Available":
                arcpy.CheckOutExtension("spatial")
                print("Licença do Spatial Analyst verificada.")
    except:
            print("Extensão do Spatial Analyst não disponível.")
            print(arcpy.GetMessages(2))

    for unit in unitList:
        try:
            for unit in unitList:
                print("Criando cláusula where para a unidade de estudo " + str(unit) + "...")
                whereRHA = '[' + rhaUnit + '] = ' + "'" + str(unit) + "'"
                whereBarrier = '[' + barrierUnit + '] = ' + "'" + str(unit) + "'"

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

                arcpy.Delete_management("currentRHA")
                arcpy.Delete_management("currentBarrier")
        except:
            print(arcpy.GetMessages(2))
        finally:
            arcpy.CheckInExtension("spatial")
            print("Licença do Spatial verificada novamente.")


        mxd = arcpy.mapping.MapDocument("CURRENT")
        df = arcpy.mapping.ListDataFrames(mxd, "Layers")[0]
        newLayer = arcpy.mapping.Layer(rasterOutputPath)
        arcpy.mapping.AddLayer(df, newLayer)
        arcpy.mapping.ExportToPNG(mxd, os.path.join(output_folder, f"{feat}_{unit}.png"))
