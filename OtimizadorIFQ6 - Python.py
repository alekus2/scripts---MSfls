---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-6-ada6743c24ad> in <cell line: 0>()
    326     "/content/Cadastro SGF (correto).xlsx"
    327 ]
--> 328 otimizador.validacao(arquivos)

1 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/generic.py in __getattr__(self, name)
   6297         ):
   6298             return self[name]
-> 6299         return object.__getattribute__(self, name)
   6300 
   6301     @final

AttributeError: 'DataFrame' object has no attribute 'str'
