package Bio::Tradis::RunTradis;

# ABSTRACT: Perform all steps required for a tradis analysis

=head1 SYNOPSIS

Takes a fastq file with tags already attached, filters the tags matching user input,
removes the tags, maps to a reference (.fa) and generates insertion site plots for use in
Artemis

   use Bio::Tradis::RunTradis;
   
   my $pipeline = Bio::Tradis::RunTradis->new(
					fastqfile => 'abc',  
					reference => 'abc',
					tag => 'abc',
					tagdirection => '5'|'3'
   );
   $pipeline->run_tradis();

=cut

use Moose;
use File::Temp;
use Bio::Tradis::FilterTags;
use Bio::Tradis::RemoveTags;
use Bio::Tradis::Map;
use Bio::Tradis::TradisPlot;

has 'fastqfile'     => ( is => 'rw', isa => 'Str',        required => 1 );
has 'fastqfile2'    => ( is => 'rw', isa => 'Maybe[Str]', required => 0 );
has 'tag'           => ( is => 'ro', isa => 'Str',        required => 1 );
has 'tagdirection'  => ( is => 'ro', isa => 'Str',        required => 1 );
has 'mapping_score' => ( is => 'ro', isa => 'Int',        required => 1 );
has 'reference'     => ( is => 'rw', isa => 'Str',        required => 1 );
has 'outfile'       => ( is => 'rw', isa => 'Str',        required => 0 );
has 'destination'   => (
    is       => 'rw',
    isa      => 'File::Temp::Dir',
    required => 0,
    default  => sub { File::Temp->newdir( CLEANUP => 1 ); }
);
has '_stats_handle' => ( 
	is => 'ro',
	isa => 'FileHandle',
	required => 0,
	lazy => 1,
	builder => '_build__stats_handle'
);
has '_plotfile'  => ( 
	is => 'rw',
	isa => 'Str',
	required => 0,
	builder => '_build__plotfile'
);


sub _build__stats_handle {
	my ($self)                = @_;
	my $outfile               = $self->outfile;
	
	open(my $stats, ">", "$outfile.stats");
	return $stats;
}

sub _build__plotfile {
	my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $outfile               = $self->outfile;

	my $seqname = `grep \@SQ $destination_directory/mapped.sam | awk '{print $2}' | sed s/SN://`;
	return "$outfile.$seqname.insert_site_plot.gz";
}

sub run_tradis {
    my ($self) = @_;
    my $destination_directory = $self->destination->dirname();

    # Step 1: Filter tags that match user input tag
    $self->_filter;

    # Step 2: Remove the tag from the sequence and quality strings
    $self->_remove;
    
    #Step 3: Map file to reference
    $self->_map;
    
    #Step 3.5: Convert output from SAM to BAM
    $self->_sam2bam;
    
    #Step 4: Generate plot
    $self->_make_plot;
    
    #Step 5: Generate statistics
    $self->_stats;
    
    #Clean up
    unlink("$destination_directory/filter.fastq");
    unlink("$destination_directory/tags_removed.fastq");
    unlink("$destination_directory/mapped.sam");
    unlink("$destination_directory/ref.index.sma");
    unlink("$destination_directory/ref.index.smi");
    unlink("$destination_directory/mapped.bam");
    unlink("$destination_directory/tmp.plot");

    return 1;
}

sub _filter {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $fqfile                = $self->fastqfile;
    my $tag                   = $self->tag;

    my $filter = Bio::Tradis::FilterTags->new(
        fastqfile => $fqfile,
        tag       => $tag,
        outfile   => "$destination_directory/filter.fastq"
    )->filter_tags;
}

sub _remove {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $tag                   = $self->tag;

    my $rm_tags = Bio::Tradis::RemoveTags->new(
        fastqfile => "$destination_directory/filter.fastq",
        tag       => $tag,
        outfile   => "$destination_directory/tags_removed.fastq"
    )->remove_tags;
}

sub _map {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $ref                   = $self->reference;

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => "$destination_directory/tags_removed.fastq",
        reference => "$ref",
        refname   => "$destination_directory/ref.index",
        outfile   => "$destination_directory/mapped.sam"
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

sub _sam2bam {
    my ($self) = @_;
    my $destination_directory = $self->destination->dirname;

    system(
"samtools view -b -o $destination_directory/mapped.bam -S $destination_directory/mapped.sam"
    );
	return 1;
}

sub _make_plot {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $ref                   = $self->reference;
    my $outfile               = $self->outfile;
    my $tr_d = $self->

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile => "$destination_directory/mapped.bam",
        reference  => "$ref",
        mapping_score => $self->mapping_score,
        outfile    => "$outfile"
    )->plot;
    
    # if tag direction is 5, reverse plot columns
    if($self->tagdirection eq '5'){
    	$self->_reverse_plot;
    }
}

sub _reverse_plot {
	my ($self)                = @_;
    my $destination_directory = $self->destination->dirname;
    my $outfile               = $self->outfile;
    
    my $plotname = $self->_plotfile;
	system("gunzip -c $plotname > $destination_directory/tmp.plot");
	system("awk '{ t = $1; $1 = $2; $2 = t; print; }' $destination_directory/tmp.plot > rv_plot");
	system("gzip -c rv_plot > $plotname");
	
	unlink("$destination_directory/tmp.plot");
	unlink("rv_plot");
}

sub _stats {
	my ($self) = @_;
	my $outfile               = $self->outfile;
    my $destination_directory = $self->destination->dirname;
    my @fields = ("File", "Total Reads", "Reads Matched", "\% Matched", "Reads Mapped", "\% Mapped", "Unique Insertion Sites");
	my $stats = join("\t", @fields) . "\n";
	
	# Add file name and number of reads in it
	$stats .= "$self->fastqfile\t";
	my $total_reads = `grep -c "^\@" $self-fastqfile`;
	chomp($total_reads);
	$stats .=  "$total_reads\t";
	
	# Matching reads
	my $matching = `grep -c "^\@" $destination_directory/filter.fastq`;
	chomp($matching);
	$stats .= "$matching\t";
	$stats .= (float($matching)/int($total_reads))*100 . "\t";
	
	# Mapped reads
	my $mapped = `grep -v -c "^\@" $destination_directory/mapped.sam`;
	chomp($mapped);
	$stats .= "$mapped\n";
	$stats .= (float($mapped)/int($matching))*100 . "\t";
	
	# Unique insertion sites
	my $plotname = $self->_plotfile;
	system("gunzip -c $plotname > $destination_directory/tmp.plot");
	my $uis = `grep -v "^0" tmp.plot | sort | uniq | wc | awk '{ print $1 }'`;
	$stats .= "$uis\n";
	
	print {$self->_stats_handle} $stats;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
