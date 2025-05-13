df_final['equipe_2'] = df_final['EQUIPE']
df_final['Dt_medição'] = df_final['DT_INICIAL']
df_final['chave_2'] = (
    df_final['CD_PROJETO'].astype(str) + '-' +
    df_final['CD_TALHAO'].astype(str) + '-' +
    df_final['NM_PARCELA'].astype(str)
)
df_final['Ht_média'] = df_final['ht média'].apply(lambda x: f"{x:.1f}".replace('.',','))
df_final = df_final.sort_values(
    by=['CD_PROJETO','CD_TALHAO','NM_PARCELA','nm_cova_ordenado']
)
df_final = df_final[['equipe_2','Dt_medição','chave_2','nm_cova_ordenado','Ht_média']]

KeyError                                  Traceback (most recent call last)
/usr/local/lib/python3.11/dist-packages/pandas/core/indexes/base.py in get_loc(self, key)
   3804         try:
-> 3805             return self._engine.get_loc(casted_key)
   3806         except KeyError as err:

index.pyx in pandas._libs.index.IndexEngine.get_loc()

index.pyx in pandas._libs.index.IndexEngine.get_loc()

pandas/_libs/hashtable_class_helper.pxi in pandas._libs.hashtable.PyObjectHashTable.get_item()

pandas/_libs/hashtable_class_helper.pxi in pandas._libs.hashtable.PyObjectHashTable.get_item()

KeyError: 'ht média'

The above exception was the direct cause of the following exception:

KeyError                                  Traceback (most recent call last)
3 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/indexes/base.py in get_loc(self, key)
   3810             ):
   3811                 raise InvalidIndexError(key)
-> 3812             raise KeyError(key) from err
   3813         except TypeError:
   3814             # If we have a listlike key, _check_indexing_error will raise

KeyError: 'ht média'
