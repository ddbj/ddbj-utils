# Rscript accession_master2bpbs.R
#
#  Created by Andrea Ghelfi on 2023/03/24, modified 2023/04/20
#  
library(data.table)
library(stringr)
ncbi <- fread("source/trad_bulk.tsv", header=T, fill=TRUE, sep="\t")[, c(3,4,10,11)]
ncbi$master <- as.data.frame(str_split(ncbi$file, "[.]", simplify=T))[,1]
ncbi$len_master <- nchar(ncbi$master)
ncbi <- ncbi[ncbi$file != "file" & ncbi$len_master > 0,]
# accession with 4 characters
accession_len4 <- ncbi[ncbi$len_master == 4]
accession_len4$master <- paste(accession_len4$master, "00000000", sep="")
# accession with 6 characters
accession_len6 <- ncbi[ncbi$len_master == 6]
accession_len6$master <- paste(accession_len6$master, "000000000", sep="")
ncbi <- rbind(accession_len4, accession_len6)
# # accession to bioproject
master2bp <- unique(ncbi[, c('master','BioProject')])
master2bp <- master2bp[complete.cases(master2bp), ]
master2bp <-  master2bp[master2bp$BioProject != "",]
fwrite(master2bp, "master_accession2bioproject.tsv", row.names=F, col.names=F, quote=F, sep="\t")
# accession to biosample
master2bs <- unique(ncbi[, c('master','BioSample')])
master2bs <-  master2bs[master2bs$BioSample != "",]
master2bs <- master2bs[complete.cases(master2bs), ]
fwrite(master2bs, "../insdc_master-biosample/master_accession2biosample.tsv", row.names=F, col.names=F, quote=F, sep="\t")
