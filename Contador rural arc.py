import arcpy
arcpy.env.workspace = "G:\\aleks"

inTable = "Teste_gerador_parcelas_131224.dbf"
outTable = "G:\\aleks\\TabelaSaida.dbf" 
tempTableView = "ESCREVA O NOME DA COLUNA AQUI"

if arcpy.Exists(inTable):
    arcpy.CopyRows_management(inTable, outTable)
    
    arcpy.MakeTableView_management(outTable, tempTableView)

    expression = arcpy.AddFieldDelimiters(tempTableView, "Measure") + " = 0"

    arcpy.SelectLayerByAttribute_management(tempTableView, "NEW_SELECTION", expression)

    if int(arcpy.GetCount_management(tempTableView)[0]) > 0:
        arcpy.DeleteRows_management(tempTableView)

    arcpy.Delete_management(tempTableView)