UnboundLocalError                         Traceback (most recent call last)
<ipython-input-8-7f2946117a23> in <cell line: 0>()
    296     "/content/Cadastro SGF (correto).xlsx"
    297 ]
--> 298 otimizador.validacao(arquivos)

<ipython-input-8-7f2946117a23> in validacao(self, paths)
    244         df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]
    245 
--> 246         with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:
    247             df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)
    248 

UnboundLocalError: cannot access local variable 'out' where it is not associated with a value
