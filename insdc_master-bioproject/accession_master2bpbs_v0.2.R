# Rscript accession_master2bpbs.R
#
#  Created by Andrea Ghelfi on 2023/03/24, modified 2023/04/21
#  
library(data.table)
library(stringr)
ncbi <- fread("source/trad_bulk.tsv", header=T, fill=TRUE, sep="\t")[, c(3,4,10,11)]
ncbi$master <- as.data.frame(str_split(ncbi$file, "[.]", simplify=T))[,1]
ncbi$len_master <- nchar(ncbi$master)
colnames(ncbi)[colnames(ncbi) == "accession number"] <- "accession_number"
ncbi$accession <- as.data.frame(str_split(ncbi$accession_number, "[-]", simplify=T))[,1]
ncbi$len_accession <- nchar(ncbi$accession)
ncbi$numb_zeros <- ncbi$len_accession - ncbi$len_master
ncbi <- as.data.frame(ncbi[ncbi$file != "file" & ncbi$len_master > 0,])
# find number of zeros
list_numb_zeros <- unique(ncbi$numb_zeros)
i <- 1
ncbi_master <- c()
for(i in 1:length(list_numb_zeros)){
    numb_zeros <- list_numb_zeros[i]
    temp_ncbi_master <- ncbi[ncbi$numb_zeros == numb_zeros,]
    zero <- paste(rep(0, numb_zeros), collapse = "")
    temp_ncbi_master$master <- paste(temp_ncbi_master$master, zero, sep="")
    ncbi_master <- rbind(ncbi_master, temp_ncbi_master)
}
# accession to bioproject
master2bp <- unique(ncbi_master[, c('master','BioProject')])
master2bp <- master2bp[grep("PRJN|PRJD|PRJE", master2bp$BioProject),]
master2bp <- master2bp[complete.cases(master2bp), ]
fwrite(master2bp, "master_accession2bioproject.tsv", row.names=F, col.names=F, quote=F, sep="\t")
# accession to biosample
master2bs <- unique(ncbi_master[, c('master','BioSample')])
master2bs <- master2bs[grep("SAMN|SAMD|SAME", master2bs$BioSample),]
master2bs <- master2bs[complete.cases(master2bs), ]
fwrite(master2bs, "../insdc_master-biosample/master_accession2biosample.tsv", row.names=F, col.names=F, quote=F, sep="\t")
