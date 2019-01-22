# Bio-Tradis
A set of tools to analyse the output from TraDIS analyses  

[![Build Status](https://travis-ci.org/sanger-pathogens/Bio-Tradis.svg?branch=master)](https://travis-ci.org/sanger-pathogens/Bio-Tradis)  
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-brightgreen.svg)](https://github.com/sanger-pathogens/Bio-Tradis/blob/master/software_license)  
[![status](https://img.shields.io/badge/Bioinformatics-10.1093-brightgreen.svg)](https://doi.org/10.1093/bioinformatics/btw022)  
[![Docker Build Status](https://img.shields.io/docker/build/sangerpathogens/bio-tradis.svg)](https://hub.docker.com/r/sangerpathogens/bio-tradis)  
[![Docker Pulls](https://img.shields.io/docker/pulls/sangerpathogens/bio-tradis.svg)](https://hub.docker.com/r/sangerpathogens/bio-tradis)  
[![codecov](https://codecov.io/gh/sanger-pathogens/bio-tradis/branch/master/graph/badge.svg)](https://codecov.io/gh/sanger-pathogens/bio-tradis)

## Contents
  * [Introduction](#introduction)
  * [Installation](#installation)
    * [Required dependencies](#required-dependencies)
    * [Bioconda](#bioconda)
    * [Docker](#docker)
    * [Running the tests](#running-the-tests)
  * [Usage](#usage)
    * [Scripts](#scripts)
    * [Analysis Scripts](#analysis-scripts)
    * [Internal Objects and Methods](#internal-objects-and-methods)
    * [Perl Programming Examples](#perl-programming-examples)
  * [License](#license)
  * [Feedback/Issues](#feedbackissues)
  * [Citation](#citation)

## Introduction 
The Bio::TraDIS pipeline provides software utilities for the processing, mapping, and analysis of transposon insertion sequencing data. The pipeline was designed with the data from the TraDIS sequencing protocol in mind, but should work with a variety of transposon insertion sequencing protocols as long as they produce data in the expected format.

For more information on the TraDIS method, see http://bioinformatics.oxfordjournals.org/content/32/7/1109 and http://genome.cshlp.org/content/19/12/2308.

## Installation
Bio-Tradis has the following dependencies:

### Required dependencies
* smalt
* samtools
* tabix
* R
* Bioconductor

There are a number of ways to install Bio-Tradis and details are provided below. If you encounter an issue when installing Bio-Tradis please contact your local system administrator. If you encounter a bug please log it [here](https://github.com/sanger-pathogens/Bio-Tradis/issues) or email us at path-help@sanger.ac.uk.

### Bioconda
Install conda and enable the bioconda channel.

```
conda config --add channels r
conda config --add channels defaults
conda config --add channels conda-forge
conda config --add channels bioconda
conda install biotradis
```

### Docker
Bio-Tradis can be run in a Docker container. First install Docker, then install Bio-Tradis:

    docker pull sangerpathogens/bio-tradis

To use Bio-Tradis use a command like this (substituting in your directories), where your files are assumed to be stored in /home/ubuntu/data:

    docker run --rm -it -v /home/ubuntu/data:/data sangerpathogens/bio-tradis bacteria_tradis -h

### Running the tests
The test can be run with dzil from the top level directory:  
  
`dzil test`  

## Usage

For command-line usage instructions, please see the tutorial in the file "BioTraDISTutorial.pdf". Note that default parameters are for comparative experiments, and will need to be modified for gene essentiality studies.

Bio-Tradis provides functionality to:
* detect TraDIS tags in a BAM file
* add the tags to the reads
* filter reads in a FastQ file containing a user defined tag
* remove tags
* map to a reference genome
* create an insertion site plot file
  
The functions are avalable as standalone scripts or as perl modules.

### Scripts
Executable scripts to carry out most of the listed functions are available in the `bin`:

* `check_tradis_tags` - Prints 1 if tags are present, prints 0 if not.
* `add_tradis_tags` - Generates a BAM file with tags added to read strings.
* `filter_tradis_tags` - Create a fastq file containing reads that match the supplied tag
* `remove_tradis_tags` - Creates a fastq file containing reads with the supplied tag removed from the sequences
* `tradis_plot` - Creates an gzipped insertion site plot
* `bacteria_tradis` - Runs complete analysis, starting with a fastq file and produces mapped BAM files and plot files for each file in the given file list and a statistical summary of all files. Note that the -f option expects a text file containing a list of fastq files, one per line.

A help menu for each script can be accessed by running the script with no parameters.

### Analysis Scripts
Three scripts are provided to perform basic analysis of TraDIS results in `bin`:

* `tradis_gene_insert_sites` - Takes genome annotation in embl format along with plot files produced by bacteria_tradis and generates tab-delimited files containing gene-wise annotations of insert sites and read counts.
* `tradis_essentiality.R` - Takes a single tab-delimited file from tradis_gene_insert_sites to produce calls of gene essentiality. Also produces a number of diagnostic plots.
* `tradis_comparison.R` - Takes tab files to compare two growth conditions using edgeR. This analysis requires experimental replicates.


### Internal Objects and Methods
__Bio::Tradis::DetectTags__  
* Required parameters:
	* `bamfile` - path to/name of file to check
* Methods:
	* `tags_present` - returns true if TraDIS tags are detected in `bamfile`
	
__Bio::Tradis::AddTagsToSeq__  
* Required parameters:
	* `bamfile` - path to/name of file containing reads and tags
* Optional parameters:
	* `outfile` - defaults to `file.tr.bam` for an input file named `file.bam`
* Methods:
	* `add_tags_to_seq` - add TraDIS tags to reads. For unmapped reads, the tag
					  is added to the start of the read sequence and quality
					  strings. For reads where the flag indicates that it is
					  mapped and reverse complemented, the reverse complemented
					  tags are added to the end of the read strings.
					  This is because many conversion tools (e.g. picard) takes
					  the read orientation into account and will re-reverse the
					  mapped/rev comp reads during conversion, leaving all tags
					  in the correct orientation at the start of the sequences
					  in the resulting FastQ file.

__Bio::Tradis::FilterTags__  
* Required parameters:
	* `fastqfile` - path to/name of file to filter. This may be a gzipped fastq file, in which case a temporary unzipped version is used and removed on completion.
	* `tag`       - TraDIS tag to match
* Optional parameters:
	* `mismatch` - number of mismatches to allow when matching the tag. Default = 0
	* `outfile`  - defaults to `file.tag.fastq` for an input file named `file.fastq`
* Methods:
	* `filter_tags` - output all reads containing the tag to `outfile`
	
__Bio::Tradis::RemoveTags__  
* Required parameters:
	* `fastqfile` - path to/name of file to filter.
	* `tag`       - TraDIS tag to remove
* Optional parameters:
	* `mismatch` - number of mismatches to allow when removing the tag. Default = 0
	* `outfile`  - defaults to `file.rmtag.fastq` for and input file named `file.fastq`
* Methods:
	* `remove_tags` - output all reads with the tags removed from both sequence and
				  quality strings to `outfile`
				
__Bio::Tradis::Map__  
* Required parameters:
	* `fastqfile` - path to/name of file to map to the reference
	* `reference` - path to/name of reference genome in fasta format (.fa)
* Optional parameters:
	* `refname` - name to assign to the reference index files. Default = ref.index
	* `outfile` - name to assign the mapped SAM file. Default = mapped.sam
* Methods:
	* `index_ref` - create index files of the reference genome. These are required
				for the mapping step. Only skip this step if index files already
				exist. -k and -s options for referencing are calculated based
				on the length of the reads being mapped:
		* <70 : `-k 13 -s 4`
		* >70 & <100 : `-k 13 -s 6`
		* >100 : `-k 20 -s 13`
	* `do_mapping` - map `fastqfile` to `reference`. Options used for mapping are:
				 `-r -1, -x and -y 0.96`
				
	For more information on the mapping and indexing options discussed here, see the SMALT manual (ftp://ftp.sanger.ac.uk/pub4/resources/software/smalt/smalt-manual-0.7.4.pdf)
				
__Bio::Tradis::TradisPlot__  
* Required parameters:
	* `mappedfile` - mapped and sorted BAM file
* Optional parameters:
	* `outfile` - base name to assign to the resulting insertion site plot. Default = tradis.plot
	* `mapping_score` - cutoff value for mapping score. Default = 30
* Methods:
	* `plot` - create insertion site plots for reads in `mappedfile`. This file will be readable by the Artemis genome browser (http://www.sanger.ac.uk/resources/software/artemis/)
	 
__Bio::Tradis::RunTradis__  
* Required parameters:
	* `fastqfile` - file containing a list of fastqs (gzipped or raw) to run the 
				complete analysis on. This includes all (including 
				intermediary format conversion and sorting) steps starting from
				filtering and, finally, producing an insertion site plot and a 
				statistical summary of the analysis.
	* `tag` - TraDIS tag to filter for and then remove
	* `reference` - path to/name of reference genome in fasta format (.fa)
* Optional parameters:
	* `mismatch` - number of mismatches to allow when filtering/removing the tag. Default = 0
	* `tagdirection` - direction of the tag, 5' or 3'. Default = 3
	* `mapping_score` - cutoff value for mapping score. Default = 30
* Methods:
	* `run_tradis` - run complete analysis

### Perl Programming Examples
You can reuse the Perl modules as part of other Perl scripts. This section provides example Perl code.
Check whether `file.bam` contains TraDIS tag fields and, if so, adds the tags
to the reads' sequence and quality strings.

```Perl
my $detector = Bio::Tradis::DetectTags(bamfile => 'file.bam');
if($detector->tags_present){
	Bio::Tradis::AddTagsToSeq(bamfile => 'file.bam', outfile => 'tradis.bam')->add_tags_to_seq;
}
```
Filter a FastQ file with TraDIS tags attached for those matching the given tag.
Then, remove the same tag from the start of all sequences in preparation for mapping.

```Perl
Bio::Tradis::FilterTags(
	fastqfile => 'tradis.fastq',
	tag => 'TAAGAGTGAC', 
	outfile => 'filtered.fastq'
)->filter_tags;
Bio::Tradis::RemoveTags(
	fastqfile => 'filtered.fastq',
	tag => 'TAAGAGTGAC', 
	outfile => 'notags.fastq'
)->remove_tags;
```
Create mapping object, index the given reference file and then map the
fastq file to the reference. This will produce index files for the reference and a mapped SAM file named `tradis_mapped.sam`.

```Perl
my $mapping = Bio::Tradis::Map(
	fastqfile => 'notags.fastq', 
	reference => 'path/to/reference.fa', 
	outfile => 'tradis_mapped.sam'
);
$mapping->index_ref;
$mapping->do_mapping;
```
Generate insertion site plot for only reads with a mapping score >= 50

```Perl
Bio::Tradis::TradisPlot(mappedfile => 'mapped.bam', mapping_score => 50)->plot;
```
Run complete analysis on fastq files listed in `file.list`. This includes filtering and removing the tags allowing one mismatch to the given tag, mapping, BAM sorting and creation of an insertion site plot and stats file for each file listed in `file.list`.

```Perl
Bio::Tradis::RunTradis(
	fastqfile => 'file.list', 
	tag => 'GTTGAGGCCA', 
	reference => 'path/to/reference.fa', 
	mismatch => 1
)->run_tradis;
```
## License
Bio-Tradis is free software, licensed under [GPLv3](https://github.com/sanger-pathogens/Bio-Tradis/blob/master/software_license).

## Feedback/Issues
Please report any issues to the [issues page](https://github.com/sanger-pathogens/bio-tradis/issues) or email path-help@sanger.ac.uk

## Citation
If you use this software please cite:


"The TraDIS toolkit: sequencing and analysis for dense transposon mutant libraries", Barquist L, Mayho M, Cummins C, Cain AK, Boinett CJ, Page AJ, Langridge G, Quail MA, Keane JA, Parkhill J. Bioinformatics. 2016 Apr 1;32(7):1109-11. doi: [10.1093/bioinformatics/btw022](https://doi.org/10.1093/bioinformatics/btw022). Epub 2016 Jan 21.
