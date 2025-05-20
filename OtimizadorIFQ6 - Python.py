---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-4-30bc0bb3c746> in <cell line: 0>()
    318     "/content/Cadastro SGF (correto).xlsx"
    319 ]
--> 320 otimizador.validacao(arquivos)

1 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/tools/numeric.py in to_numeric(arg, errors, downcast, dtype_backend)
    204         values = np.array([arg], dtype="O")
    205     elif getattr(arg, "ndim", 1) > 1:
--> 206         raise TypeError("arg must be a list, tuple, 1-d array, or Series")
    207     else:
    208         values = arg

TypeError: arg must be a list, tuple, 1-d array, or Series
