import re

def ensure_two_digit_suffix(idx):
    idx = str(idx)
    # se já termina em -DD (dois dígitos), está ok
    if re.search(r'-\d{2}$', idx):
        return idx
    # se termina em -D (um dígito), converte para -0D
    if re.search(r'-\d$', idx):
        return re.sub(r'-(\d)$', r'-0\1', idx)
    # se não tem sufixo, adiciona -01
    return idx + "-01"

# aplica ao DataFrame inteiro
df_final["Index"] = df_final["Index"].map(ensure_two_digit_suffix)
