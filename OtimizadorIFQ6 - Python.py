ValueError                                Traceback (most recent call last)
<ipython-input-3-cb7765040dfe> in <cell line: 0>()
    316     "/content/Cadastro SGF (correto).xlsx"
    317 ]
--> 318 otimizador.validacao(arquivos)

9 frames
lib.pyx in pandas._libs.lib.map_infer()

<ipython-input-3-cb7765040dfe> in <lambda>(x)
    281         metrics_D = df_D_tabela.apply(_calc_row, axis=1)
    282         df_D_tabela = pd.concat([df_D_tabela, metrics_D], axis=1)
--> 283         df_D_tabela["PV50"] = df_D_tabela["PV50"].map(lambda x: f"{x:.2f}%".replace(".", ","))
    284         with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:
    285             df_D_tabela.to_excel(w, sheet_name="D_Tabela_Resultados_Ht3", index=False)

ValueError: Unknown format code 'f' for object of type 'str'
