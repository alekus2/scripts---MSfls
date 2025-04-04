# Parte do código que verifica CD_01 e ajusta NM_COVA
for idx in range(1, len(df_final)):
    atual = df_final.iloc[idx]
    anterior = df_final.iloc[idx - 1]
    
    if atual['NM_FILA'] == anterior['NM_FILA']:
        if atual['CD_01'] == 'L' and anterior['CD_01'] == 'N':
            df_final.at[idx, 'NM_COVA'] = anterior['NM_COVA']  # Ajuste aqui
            
df_final['check SQC'] = 'OK'  # Inicializa com 'OK'
for idx in range(1, len(df_final)):
    atual = df_final.iloc[idx]
    anterior = df_final.iloc[idx - 1]
    
    if atual['NM_FILA'] == anterior['NM_FILA']:
        if anterior['CD_01'] == 'N' and atual['CD_01'] == 'L':
            df_final.at[idx, 'check SQC'] = 'VERIFICAR'