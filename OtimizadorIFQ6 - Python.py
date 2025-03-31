df.columns = [str(col).upper() if isinstance(col, str) else f"COLUNA_{i}" for i, col in enumerate(df.columns)]
