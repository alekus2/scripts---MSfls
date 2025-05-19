        def _calc_row(row):
            # pega todos os valores das colunas de cova; nan vira 0
            valores = [0 if pd.isnull(row[c]) else row[c] for c in num_cols]
            
            # n = total de covas (conta zeros também)
            n = len(valores)
            
            # metades para PV50
            meio = n // 2
            
            # mediana de todos os valores (incluindo zeros)
            med = np.median(valores) if valores else 0.0
            
            # soma total (incluindo zeros)
            soma_total = sum(valores)
            
            # soma dos menores ou iguais à mediana, para PV50
            # ordena valores para pegar os primeiros 'meio'
            ordenados = sorted(valores)
            if n % 2 == 0:
                soma_le = sum(v for v in ordenados[:meio] if v <= med)
            else:
                soma_le = sum(ordenados[:meio]) + med/2.0
            
            # percentual acumulado até 50% da soma
            pv50 = (soma_le / soma_total * 100.0) if soma_total else 0.0
            
            return pd.Series({
                "n": n,
                "n/2": meio,
                "Mediana": med,
                "∑Ht": soma_total,
                "∑Ht(<=Med)": soma_le,
                "PV50": pv50
            })
