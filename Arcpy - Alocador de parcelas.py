id_talhoes_str = ",".join([f"'{x}'" for x in id_talhoes])  # Lista de strings corretamente formatadas
query = f"ID_TALHAO IN ({id_talhoes_str})"
