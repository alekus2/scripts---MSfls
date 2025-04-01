df_filtrado['check dup'] = df_filtrado.duplicated(subset=dup_columns, keep=False).map({True: 'VERIFICAR', False: 'OK'})

df_filtrado['CHAVE_DUPLICADA'] = df_filtrado[dup_columns].astype(str).agg('-'.join, axis=1)
df_filtrado['CHAVE_DUPLICADA'] = df_filtrado.apply(
    lambda row: row['CHAVE_DUPLICADA'] if row['check dup'] == 'VERIFICAR' else '',
    axis=1
)

# Nova verificação para 'CD_01' com código "L" e 'NM_FUSTE' == 1
df_filtrado['check cd_01'] = df_filtrado.apply(
    lambda row: 'VERIFICAR' if row['CD_01'] == 'L' and row['NM_FUSTE'] == 1 else 'OK',
    axis=1
)
