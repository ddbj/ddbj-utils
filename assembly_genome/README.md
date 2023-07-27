## Assembly Genome 
Download from NCBI

```
curl -O "https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_genbank.txt"
```
Obs.: It takes about 30 seconds to download the complete file.

### Prepare pairs
#### assembly_genome-BioProject
```
awk -F"\t" -v OFS="\t" ' NR > 2 && $2 !="" && $2 !="na" {print $2,$1}' assembly_summary_genbank.txt | awk -F"[.]" '{print $1}' | awk -F"\t" -v OFS="\t" '{print $2,$1}' > dblink/assembly_genome-bp/assembly_genome2bp.tsv;
```
#### assembly_genome-BioSample
```
awk -F"\t" -v OFS="\t" ' NR > 2 && $3 !="" && $3 !="na" {print $3,$1}' assembly_summary_genbank.txt | awk -F"[.]" '{print $1}' | awk -F"\t" -v OFS="\t" '{print $2,$1}' > dblink/assembly_genome-bs/assembly_genome2bs.tsv;
```
#### assembly_genome-insdc
```
awk -F"\t" -v OFS="." ' NR > 2 && $4 !="" && $4 !="na" {print $1,$4}' assembly_summary_genbank.txt | awk -F"[.]" -v OFS="\t" '{print $1,$3}' > dblink/assembly_genome-insdc/assembly_genome2insdc.tsv;
```
#### [Update Public URL](https://ddbj.nig.ac.jp/public/rdf/dblink/)
