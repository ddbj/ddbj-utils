# Rscript accession2bpbs.R
#
#  Created by Andrea Ghelfi on 2023/03/24.
#  
library(data.table)
library(stringr)
ncbi <- fread("source/trad_bulk.tsv", header=T, fill=TRUE, sep="\t")[, c(3,4,10,11)]
ncbi$master <- as.data.frame(str_split(ncbi$file, "[.]", simplify=T))[,1]
ncbi$len_master <- nchar(ncbi$master)
colnames(ncbi)[2] <- "accession_number"
ncbi$master <- substr(ncbi$accession_number, 1, ncbi$len_master + 2)
ncbi <- ncbi[ncbi$len_master > 0,]
master2bp <- ncbi[, c('master','BioProject')]
master2bp <- master2bp[complete.cases(master2bp), ]
master2bp <-  master2bp[master2bp$BioProject != "",]
fwrite(master2bp, "bulk_accession2bioproject.tsv", row.names=F, col.names=F, quote=F, sep="\t")
master2bs <- ncbi[, c('master','BioSample')]
master2bs <-  master2bs[master2bs$BioSample != "",]
master2bs <- master2bs[complete.cases(master2bs), ]
fwrite(master2bs, "../insdc-biosample/bulk_accession2biosample.tsv", row.names=F, col.names=F, quote=F, sep="\t")
