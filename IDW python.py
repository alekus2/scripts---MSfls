# Import modules, setup overwrite in environments
import arcpy
from arcpy.sa import *
import arcpy.mapping as mapping
import pandas as pd
import os

arcpy.env.overwriteOutput = True

# --- Parte 1: Ler os dados do Excel ---
try:
    arquivo_excel = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Automações em python\IDW python\IDW piracicaba.csv'

    if not os.path.exists(arquivo_excel):
        raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")

    df = pd.read_excel(arquivo_excel, sheet_name=0)

    colunas_esperadas = ['Name','Parcela','F_Sobreviv']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")

    porcentagem_SBV= []
    valores_sobrevivencia = df['F_Sobreviv'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")

def decimal_to_percentage(decimal_number, decimal_places=2):
    percentage = decimal_number * 100
    return f"{percentage:.{decimal_places}f}%"


# Create file paths
barrier = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/WetlandBarrier/"
rhaPoints = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/RHA_Waypoints"
habitatData = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/NutriaProj.mdb/habitatDetails"
outPath = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/"
rasterPath = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/Rasters/"
rhaLayer = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/RHA_Waypoints.lyr"
mxdPath = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/MapDocument.mxd"

# Define output folder for maps
mapOutputFolder = "P:/Employee_GIS_Data/Hewitt_GIS_Data/Python/OutputMaps/"

# Create field variables
rhaField = "IDENT"
habitatField = "PointName"
rhaUnit = "ModelUnit"
barrierUnit = "ModelUnit"

# Create List Variables
fieldList = []
unitList = [1,2,3,4,5,6,7,8]

# Create join between RHA points and Habitat data table
try:
    print("Joining waypoints with habitat data...")
    arcpy.MakeFeatureLayer_management(rhaPoints, "rhaLyr")
    arcpy.AddJoin_management("rhaLyr", rhaField, habitatData, habitatField)
    arcpy.SaveToLayerFile_management("rhaLyr", rhaLayer)
except:
    print(arcpy.GetMessages(0))

# Create list of vegetation attributes for loop, local variables
print("Creating list of vegetation fields for IDW modeling...")
for field in arcpy.ListFields(habitatData):
    fieldList.append(field.name)
fList = fieldList[2:17]
    
power = 2  # As distance increases, point has less impact on interpolation
cellSize = 60  # Raster cell size

# Check out Spatial Analyst extension
try:
    if arcpy.CheckExtension("spatial")== "Available":
        arcpy.CheckOutExtension("spatial")
        print("Liçensa geoestatistica checada, \n Disponivel.")
except:
    print("Liçensa geoestatistica não disponivel.")
    print(arcpy.GetMessages(2))
    
try:
    for unit in unitList:
        # Create where clause for current study area.
        print("Creating where clause for study unit " + str(unit) + "...")
        whereRHA = '['+ rhaUnit + '] = ' + "'" + str(unitList[unit - 1]) + "'"
        whereBarrier = '['+ barrierUnit + '] = ' + "'" + str(unitList[unit - 1]) + "'"

        # Create feature layer for RHA waypoints and Barrier for current study unit
        arcpy.MakeFeatureLayer_management("rhaLyr", "currentRHA", whereRHA)
        arcpy.MakeFeatureLayer_management(barrier, "currentBarrier", whereBarrier)
        
        for feat in fList:
            try:
                print("Running IDW model for " + feat + "...")
                # IDW spatial analyst
                outRaster = arcpy.sa.Idw("currentRHA", "habitatDetails." + feat, cellSize, power, "", "currentBarrier")
                rasterOutputPath = rasterPath + feat + "_" + str(unit) + ".tif"
                outRaster.save(rasterOutputPath)
                print("Successfully ran IDW for " + feat + ".")
                
                # Add raster to map document
                mxd = mapping.MapDocument(mxdPath)
                df = mapping.ListDataFrames(mxd, "Layers")[0]
                newRasterLayer = mapping.Layer(rasterOutputPath)
                mapping.AddLayer(df, newRasterLayer)
                
                # Export the map
                outputMapPath = mapOutputFolder + feat + "_" + str(unit) + ".png"
                mapping.ExportToPNG(mxd, outputMapPath)
                print("Map exported for " + feat + " at unit " + str(unit) + ".")
                
            except:
                print(feat + " interpolation failed.")
                print(arcpy.GetMessages(2))

        # Delete feature layer
        arcpy.Delete_management("currentRHA")
        arcpy.Delete_management("currentBarrier")
except:
    print(arcpy.GetMessages(2))
finally:
    arcpy.CheckInExtension("spatial")
    print("Spatial license checked back in.")

print("Finished running IDW module.")
