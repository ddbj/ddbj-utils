## BioProject_Umbrella-BioProject

Extract BioProject_umbrella-BioProject from xml file (https://ddbj.nig.ac.jp/public/ddbj_database/bioproject/bioproject.xml)
```
awk -v OFS="\t" '{if($0 ~ "<ProjectIDRef archive="){bioproject=$0}; if($0 ~ "<MemberID archive=") { print bioproject, $0}}' bioproject.xml > tab_temp_ncbi_umbrella2bp.txt;
awk -F"\"" -v OFS="\t" '{print $12, $6}' tab_temp_ncbi_umbrella2bp.txt | sort | uniq > ncbi_umbrella2bp.tsv ;
```
Remove redundancies and filter BioProject IDs that do not start with "PR"
```
Rscript ~/scripts/togoid/bpUmbrella2bp.R ;
```
R script
```
library(data.table)
ncbi <- fread("source/ncbi_umbrella2bp.tsv", header=F, sep="\t")
ncbi <- ncbi[grep("PR", ncbi$V1),]
ncbi <- ncbi[grep("PR", ncbi$V2),]
ncbi <- unique(ncbi)
fwrite(ncbi, "bioprojectUmbrella2bioproject.tsv", row.names=F, col.names=F, quote=F, sep="\t")
```
Data is available at (https://ddbj.nig.ac.jp/public/rdf/dblink/bioproject_umbrella-bioproject/)
