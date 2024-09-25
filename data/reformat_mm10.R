setwd("/Users/jfr2137/Desktop/Research/Rabadan_Lab/SU2C_organoid/CINSignatureQuantification_mm10/data/")
gap_mm10 <- read.csv("gap_mm10.txt", sep="\t", header=FALSE, skip=1)
save(gap_mm10, file="gap_mm10.rda")
mm10.chrom.sizes <- read.csv("mm10.chrom.sizes.txt", sep="\t",
                             header=FALSE)
mm10.chrom.sizes <- mm10.chrom.sizes[mm10.chrom.sizes$V1 != "chrM", ]
save(mm10.chrom.sizes, file="mm10.chrom.sizes.rda")