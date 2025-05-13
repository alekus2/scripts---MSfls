# depois de calcular count_verificar:
if count_verificar > 0:
    # seu bloco existente para caso haja “VERIFICAR”
    …
else:
    df_final['ht média'] = df_final.groupby('NM_COVA')['NM_ALTURA'].transform('mean')
    df_final = df_final.sort_values(by=['CD_TALHAO','NM_PARCELA','NM_ALTURA'])
    df_final['nm_cova_ordenado'] = df_final.groupby(['CD_TALHAO','NM_PARCELA']).cumcount() + 1
    df_final = df_final.sort_values(by=['CD_TALHAO','NM_PARCELA','nm_cova_ordenado'])
    df_final.drop(columns=['check dup','check cd','check SQC'], inplace=True)
    nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
    contador = 1
    novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
    while os.path.exists(novo_arquivo_excel):
        contador += 1
        novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
    df_final.to_excel(novo_arquivo_excel, index=False)
    print(f"✅ Todos os dados foram unificados e salvos em '{novo_arquivo_excel}'.")
