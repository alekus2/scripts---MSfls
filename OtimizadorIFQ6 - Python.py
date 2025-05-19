        def _calc_row(row):
            # pega todos os valores das covas (zeros e não-nulos)
            valores = [0 if pd.isnull(row[c]) else row[c] for c in num_cols]
            # encontra índice do último valor > 0
            últimos = [i for i, v in enumerate(valores) if v > 0]
            if últimos:
                fim = max(últimos)
                valores = valores[:fim+1]
            else:
                valores = []
            # n = total de posições de cova até o último
            n = len(valores)
            meio = n // 2
            med = np.median(valores) if valores else 0.0
            soma_total = sum(valores)
            ordenados = sorted(valores)
            if n % 2 == 0:
                soma_le = sum(v for v in ordenados[:meio] if v <= med)
            else:
                soma_le = sum(ordenados[:meio]) + med/2.0
            pv50 = (soma_le / soma_total * 100.0) if soma_total else 0.0
            return pd.Series({
                "n": n,
                "n/2": meio,
                "Mediana": med,
                "∑Ht": soma_total,
                "∑Ht(<=Med)": soma_le,
                "PV50": pv50
            })
