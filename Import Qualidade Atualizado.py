import os
import re
import csv
import datetime
from arcgis.gis import GIS
import pandas as pd

portalURL = r'https://gissp.bracell.com/portal/'
username = "Qualidade_SP"
password = "Qualidade@21"
survey_item_id = "35572da04c8f4193a518c888f20cda75"
save_path = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Pasta de controle de mudas laudo'
keep_org_item = False
store_csv_w_attachments = True

gis = GIS(portalURL, username, password)
survey_by_id = gis.content.get(survey_item_id)

rel_fs = survey_by_id.related_items('Survey2Service', 'forward')[0]
item_excel = rel_fs.export(title=survey_by_id.title, export_format='Excel')
item_excel.download(save_path=save_path)
if not bool(keep_org_item):
    item_excel.delete(force=True)


url_base_survey = r'F:\Planejamento_e_Controle\Controles Administrativos\1. MS_MSFC FLORESTAL\05 - Compartilhada\12 - Qualidade\00 - Arquivos Survey\QLD_laudo_de_qualidade_de_mudas_em_expedicao.xlsx'
base_survey = pd.read_excel(url_base_survey)

layers = rel_fs.layers + rel_fs.tables

for i in layers:
    if i.properties.hasAttachments == True:
        feature_layer_folder = os.path.join(save_path, '{}_attachments'.format(re.sub(r'[^A-Za-z0-9]+', '', i.properties.name)))
        os.mkdir(feature_layer_folder)
        current_date = datetime.datetime.now().strftime("%Y/%m/%d")
        if bool(store_csv_w_attachments):
            csv_filename = f"{i.properties.name}_attachments_{current_date}.csv"
            path = os.path.join(feature_layer_folder, csv_filename)
        elif not bool(store_csv_w_attachments):
            csv_filename = f"{i.properties.name}_attachments_{current_date}.csv"
            path = os.path.join(save_path, csv_filename)
        csv_fields = ['Parent objectId', 'Attachment path']
        with open(path, 'w', newline='') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow_to_csv(csv_fields)
            feature_object_ids = i.query(where="1=1", return_ids_only=True, order_by_fields='objectid ASC')
            for j in range(len(feature_object_ids['objectIds'])):
                current_oid = feature_object_ids['objectIds'][j]
                current_oid_attachments = i.attachments.get_list(oid=current_oid)
                if len(current_oid_attachments) > 0:
                    for k in range(len(current_oid_attachments)):
                        attachment_id = current_oid_attachments[k]['id']
                        attachment_filename = f"{current_oid}_attachment_{attachment_id}_{current_date}.jpg" 
                        current_attachment_path = i.attachments.download(
                            oid=current_oid,
                            attachment_id=attachment_id,
                            save_path=os.path.join(feature_layer_folder, attachment_filename)
                        )
                        csvwriter.writerow([current_oid, os.path.join(feature_layer_folder, attachment_filename)])
