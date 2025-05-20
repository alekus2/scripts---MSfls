Colunas do DataFrame D_Tabela: Index(['Área (ha)', 'Chave_stand_1', 'CD_PROJETO', 'CD_TALHAO', 'nm_parcela',
       'nm_area_parcela', '1', '2', '3', '4',
       ...
       'Pits/ha', 'CST', 'Pits por sob', 'Check pits', 'n', 'n/2', 'Mediana',
       '∑Ht', '∑Ht(<=Med)', 'PV50'],
      dtype='object', length=102)
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-5-4b7f2d544bf0> in <cell line: 0>()
    322     "/content/Cadastro SGF (correto).xlsx"
    323 ]
--> 324 otimizador.validacao(arquivos)

1 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/tools/numeric.py in to_numeric(arg, errors, downcast, dtype_backend)
    204         values = np.array([arg], dtype="O")
    205     elif getattr(arg, "ndim", 1) > 1:
--> 206         raise TypeError("arg must be a list, tuple, 1-d array, or Series")
    207     else:
    208         values = arg

TypeError: arg must be a list, tuple, 1-d array, or Series
