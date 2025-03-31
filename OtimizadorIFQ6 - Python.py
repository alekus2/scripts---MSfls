try:
    df = pd.read_excel(path, sheet_name=0)
except:
    df = pd.read_excel(path, sheet_name=1)
