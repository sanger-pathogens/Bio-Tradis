Bio-Tradis
==========
Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses.
For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

Bio-Tradis provides functionality to:
* detect TraDIS tags in a BAM file
* add the tags to the reads
* filter reads in a FastQ file containing a user defined tag
* remove tags
* map to a reference genome
* create an insertion site plot file
available as standalone scripts or as perl modules.

Objects and Methods
===================
####Bio::Tradis::DetectTags
* Required parameters:
	* `bamfile` - path to/name of file to check
* Methods:
	* `tags_present` - returns true if TraDIS tags are detected in `bamfile`
	
####Bio::Tradis::AddTagsToSeq
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

####Bio::Tradis::FilterTags
* Required parameters:
	* `fastqfile` - path to/name of file to filter. This may be a gzipped fastq file, in which case a temporary unzipped version is used and removed on completion.
	* `tag`       - TraDIS tag to match
* Optional parameters:
	* `mismatch` - number of mismatches to allow when matching the tag. Default = 0
	* `outfile`  - defaults to `file.tag.fastq` for and input file named `file.fastq`
* Methods:
	* `filter_tags` - output all reads containing the tag to `outfile`
	
####Bio::Tradis::RemoveTags
* Required parameters:
	* `fastqfile` - path to/name of file to filter.
	* `tag`       - TraDIS tag to remove
* Optional parameters:
	* `mismatch` - number of mismatches to allow when removing the tag. Default = 0
	* `outfile`  - defaults to `file.rmtag.fastq` for and input file named `file.fastq`
* Methods:
	* `remove_tags` - output all reads with the tags removed from both sequence and
				  quality strings to `outfile`
				
####Bio::Tradis::Map
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
				
```
				Read length    | k  |  s
				---------------+----+-----
				<70            | 13 |  4
				>70 & <100     | 13 |  6
				>100           | 20 |  13
```

	* `do_mapping` - map `fastqfile` to `reference`. Options used for mapping are:
				 `-r -1, -x and -y 0.96`
				
	For more information on the mapping and indexing options discussed here, see the SMALT manual (ftp://ftp.sanger.ac.uk/pub4/resources/software/smalt/smalt-manual-0.7.4.pdf)
				
####Bio::Tradis::TradisPlot
* Required parameters:
	* `mappedfile` - mapped and sorted BAM file
* Optional parameters:
	* `outfile` - base name to assign to the resulting insertion site plot. Default = tradis.plot
	* `mapping_score` - cutoff value for mapping score. Default = 30
* Methods:
	* `plot` - create insertion site plots for reads in `mappedfile`. This file will be readable by the Artemis genome browser (http://www.sanger.ac.uk/resources/software/artemis/)
	 
####Bio::Tradis::RunTradis
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

Examples
========
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
Bio::Tradis::FilterTags(fastqfile => 'tradis.fastq', tag => 'TAAGAGTGAC', outfile => 'filtered.fastq')->filter_tags;
Bio::Tradis::RemoveTags(fastqfile => 'filtered.fastq', tag => 'TAAGAGTGAC', outfile => 'notags.fastq')->remove_tags;
```
Create mapping object, index the given reference file and then map the
fastq file to the reference.

```Perl
my $mapping = Bio::Tradis::Map(fastqfile => 'notags.fastq', reference => 'path/to/reference.fa');
$mapping->index_ref;
$mapping->do_mapping;
```
Generate insertion site plot for only reads with a mapping score >= 50

```Perl
Bio::Tradis::TradisPlot(mappedfile => mapped.bam, mapping_score => 50)->plot;
```
Run complete analysis on `file.tagged.fastq`. This includes filtering and removing
the tags, mapping, BAM sorting and creation of an insertion site plot and stats file.

```Perl
Bio::Tradis::RunTradis(fastqfile => 'file.tagged.fastq', tag => 'GTTGAGGCCA', reference => 'path/to/reference.fa')->run_tradis;
```


