#!/bin/sh

#  script_bulk_data.sh
#  
#
#  Created by Andrea Ghelfi on 2023/03/24.
#  
cp /usr/local/resources/trad/tpa/tls/TPA_TLS_ORGANISM_LIST.txt ./trad/bulk_data ;
cp /usr/local/resources/trad/tpa/wgs/TPA_WGS_ORGANISM_LIST.txt ./trad/bulk_data ;
cp /usr/local/resources/trad/tpa/tsa/TPA_TSA_ORGANISM_LIST.txt ./trad/bulk_data ;
cp /usr/local/resources/trad/tls/TLS_ORGANISM_LIST.txt ./trad/bulk_data ;
cp /usr/local/resources/trad/wgs/WGS_ORGANISM_LIST.txt ./trad/bulk_data ;
cp /usr/local/resources/trad/tsa/TSA_ORGANISM_LIST.txt ./trad/bulk_data ;
# merge all bulk_data
cat trad/bulk_data/*.txt > trad/trad_bulk.tsv;

Rscript accession_master2bpbs.R ;
