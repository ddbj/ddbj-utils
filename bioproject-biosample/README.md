## BioProject-BioSample

Extract bioproject-biosample from xml file (https://ddbj.nig.ac.jp/public/ddbj_database/bioproject/bioproject.xml)
```
awk -v OFS="\t" '{if($0 ~ "<ArchiveID accession="){bioproject=$2}; if($0 ~ "biosample_id=") { print bioproject, $0}}' bioproject.xml > tab_temp_ncbi_bp2bs.txt;
fgrep -v "assembly_id" tab_temp_ncbi_bp2bs.txt | awk -F"\t" -v OFS="\t" '{sub("accession=",""); gsub("\"", ""); gsub(" ", ""); sub("<LocusTagPrefix","");sub("biosample_id=",""); ; gsub("/", ""); sub(">", "\t"); print $1, $2}'  > temp_no_assembly.txt;
fgrep "assembly_id" tab_temp_ncbi_bp2bs.txt | awk -F"\t" -v OFS="\t" '{sub("accession=",""); gsub("\"", ""); gsub(" ", ""); sub("biosample_id=","\t"); sub(">", "\t"); print $1, $3}' > temp_has_assembly.txt;
cat temp_has_assembly.txt temp_no_assembly.txt > ncbi_bp2bs.tsv;
```
Remove redundancies and filter BioSample IDs that do not start with "SAM"
```
Rscript ~/scripts/togoid/bp2bs.R ;
```
R script
```
library(data.table)
ncbi <- fread("ncbi_bp2bs.tsv", header=F, sep="\t")
ncbi <- ncbi[grep("SAM", ncbi$V2),]
ncbi <- unique(ncbi)
fwrite(ncbi, "bioproject2biosample.tsv", row.names=F, col.names=F, quote=F, sep="\t")
```
