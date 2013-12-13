#!/software/R-3.0.0/bin/Rscript
library("edgeR")
library("getopt")

opt = getopt(matrix( c('help', 'h', 0, "logical", 
                       'verbose', 'v', 0, "integer",
                       'controls', 'c', 1, "character",
                       'conditions', 'm', 1, "character",
                       'output', 'o', 1, "character",
                       'plot', 'p', 1, "character"
), ncol=4, byrow=TRUE ) );

if(! is.null(opt$help) || is.null(opt$controls )  || is.null(opt$conditions ) )
{
  cat(paste("Usage: tradis_comparison.R [-h] [-o outputfile.csv] [-p outputplot.pdf] --controls controls.txt --conditions conditions.txt\n"));
  q(status=1);
}

# parse contols and conditions files to lists
control_files <- scan(opt$controls, what="", sep="\n")
condition_files <- scan(opt$conditions, what="", sep="\n")

if(length(control_files) < 2 || length(condition_files) < 2){
	print("2 or more controls/conditions must be provided")
}
if(length(control_files) != length(condition_files)){
	print("Unequal number of conditions and controls provided")
}

control_list = list()
for(i in 1:length(control_files)){
	control_list[[i]] <- read.table(control_files[i], sep="\t",header=TRUE, quote="\"", stringsAsFactors=F)
}
condition_list = list()
for(i in 1:length(condition_files)){
	condition_list[[i]] <- read.table(condition_files[i], sep="\t",header=TRUE, quote="\"", stringsAsFactors=F)
}

# set default output filename
if ( is.null(opt$output ) ) { opt$output = paste(opt$condition1,opt$control1, ".output.csv",sep = "")}

#only look at genes with counts > 0 in some condition
all_list <- c(control_list, condition_list)

# make list of rows where read count = 0 in all controls and conditions
read_counts = do.call(cbind, lapply(all_list, function(x){ x$read_count }))
zeros = apply( apply(read_counts, 1, ">", 0), 2, any )

# remove these rows
noness_list = lapply(all_list, function(x){ x[zeros,] } )

#build count matrix
count_mat <- do.call(cbind, lapply(noness_list, function(x){x[,7]}))
conds = c()
for(i in 1:length(control_files)){
	conds <- c(conds, "ctrl")
}
for(i in 1:length(condition_files)){
	conds <- c(conds, "cond")
}
conds <- as.factor(conds)


if( is.null(opt$plot) ){ opt$plot = paste(opt$condition1,opt$control1,".output.pdf",sep = "") }
pdf( opt$plot )

#edgeR
d <- DGEList(counts = count_mat, group=conds)
plotMDS.DGEList(d, labels=conds)
d <- calcNormFactors(d)
d <- estimateCommonDisp(d)
d <- estimateTagwiseDisp(d)
de.tgw <- exactTest(d,pair=c("ctrl","cond"))

ctrl1_noness <- noness_list[[1]]
diff <- cbind(ctrl1_noness[,1:2],ctrl1_noness[,11],de.tgw$table,q.value=p.adjust(de.tgw$table$PValue,"BH"))


#volcano plot
plot(diff$logFC, -log(diff$q.value, base=2), xlim=range(c(-6,6)),xlab="Log2 Fold-Change, cond - Ctrl",ylab="-Log2 Q-value", cex = .5, pch=20)
abline(h=-log(0.01), col="red")
abline(v=-2, col="red")
abline(v=2, col="red")


#write results
write.table(diff,file=opt$output,append=FALSE, quote=TRUE, sep=",", row.names=FALSE, col.names=c("locus_tag","gene_name","function","logFC","logCPM","PValue","q.value"))
