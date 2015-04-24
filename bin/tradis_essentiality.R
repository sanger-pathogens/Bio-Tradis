#!/usr/bin/env Rscript

# PODNAME: tradis_esseniality.R
# ABSTRACT: tradis_esseniality.R

library("MASS")
options(warn=-1)

args <- commandArgs(trailingOnly = TRUE)
input = args[1]

if( is.null(input) ){
	cat(paste("Usage: tradis_essentiality.R data.tab"))
	q(status=1)
}

STM_baseline <- read.table(input, sep="\t",header=TRUE,stringsAsFactors=F, quote="\"")

ii <- STM_baseline$ins_index

#identify second maxima
h <- hist(ii, breaks=100,plot=FALSE)
maxindex <- which.max(h$density[3:length(h$density)])
maxval <- h$mids[maxindex+2]

# print pdf of loess curve and later on, histogram
pdf(paste(input, "QC_and_changepoint_plots", "pdf", sep = "."))

#find inter-mode minima with loess
nG <- length(STM_baseline$read_count)
r <- floor(maxval *1000)
I = ii < r / 1000
h1 = hist(ii[I],breaks=(0:r/1000))
lo <- loess(h1$density ~ c(1:length(h1$density))) #loess smothing over density
plot(h1$density, main="Density")
lines(predict(lo),col='red',lwd=2)
m = h1$mids[which.min(predict(lo))]
I1 = ((ii < m)&(ii > 0))

h = hist(ii, breaks=100,plot=FALSE) 
I2 = ((ii >= m)&(ii < h$mids[max(which(h$counts>5))]))
f1 = (sum(I1) + sum(ii == 0))/nG
f2 = (sum(I2))/nG

d1 = fitdistr(ii[I1], "gamma")
d2 = fitdistr(ii[I2], "gamma") #fit curves

# print pdf of histogram
#pdf("Loess_and_changepoint_estimation.pdf")

#plots
hist(ii,breaks=200, xlim=c(0,0.1), freq=FALSE,xlab="Insertion index", main="Gamma fits")
lines(0:50/500, f1*dgamma(0:50/500, 1, d1$estimate[2])) # was [2]
lines(0:50/500, f2*dgamma(0:50/500, d2$estimate[1], d2$estimate[2]))
# print changepoint

#calculate log-odds ratios to choose thresholds
lower <- max(which(log((pgamma(1:300/10000, d2$e[1],d2$e[2])*(1-pgamma(1:300/10000, 1,d1$e[2], lower.tail=FALSE)))/(pgamma(1:300/10000, 1,d1$e[2], lower.tail=FALSE)*(1-pgamma(1:300/10000, d2$e[1],d2$e[2]))) , base=2) < -2))
upper <- min(which(log((pgamma(1:300/10000, d2$e[1],d2$e[2])*(1-pgamma(1:300/10000, 1,d1$e[2], lower.tail=FALSE)))/(pgamma(1:300/10000, 1,d1$e[2], lower.tail=FALSE)*(1-pgamma(1:300/10000, d2$e[1],d2$e[2]))) , base=2) > 2))

essen <- lower/10000
ambig <- upper/10000

lines(c(lower/10000, lower/10000), c(0,20), col="red")
lines(c(upper/10000, upper/10000), c(0,20), col="red")

mtext(paste(essen, ":", "Essential changepoint"), side=3, adj=1, padj=2)
mtext(paste(ambig, ":", "Ambiguous changepoint"), side=3, adj=1, padj=3.75)
dev.off()


write.csv(STM_baseline, file=paste(input, "all", "csv", sep="."), row.names = FALSE, col.names= TRUE, quote=FALSE)
write.csv(STM_baseline[STM_baseline$ins_index < essen,], file=paste(input, "essen", "csv", sep="."), row.names = FALSE, col.names= TRUE, quote=FALSE)
write.csv(STM_baseline[STM_baseline$ins_index >= essen & STM_baseline$ins_index < ambig,], file=paste(input, "ambig", "csv", sep="."), row.names = FALSE, col.names= TRUE, quote=FALSE)
