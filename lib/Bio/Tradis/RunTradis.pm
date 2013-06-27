package Bio::Tradis::RunTradis;

# ABSTRACT: Perform all steps required for a tradis analysis

=head1 SYNOPSIS

Takes a fastq file with tags already attached, filters the tags matching user input,
removes the tags, maps to a reference (.fa) and generates insertion site plots for use in
Artemis

   use Bio::Tradis::RunTradis;
   
   my $pipeline = Bio::Tradis::RunTradis->new(
					fastqfile => 'abc', 
					fastqfile2 => 'abc', 
					reference => 'abc'
   );
   $pipeline->run_tradis();

=cut

use Moose;
use File::Temp;
use Bio::Tradis::FilterTags;
use Bio::Tradis::RemoveTags;
use Bio::Tradis::Map;
use Bio::Tradis::TradisPlot;

has 'fastqfile'  => ( is => 'rw', isa => 'Str',        required => 1 );
has 'fastqfile2' => ( is => 'rw', isa => 'Maybe[Str]', required => 0 );
has 'tag'        => ( is => 'ro', isa => 'Str',        required => 1 );
has 'reference'  => ( is => 'rw', isa => 'Str',        required => 1 );
has 'outfile'    => ( is => 'rw', isa => 'Str',        required => 0 );
has 'destination' => (
    is       => 'rw',
    isa      => 'File::Temp::Dir',
    required => 0,
    default  => sub { File::Temp->newdir( CLEANUP => 1 ); }
);

sub run_tradis {
    my ($self) = @_;
    my $destination_directory = $self->destination->dirname();

    # Step 1: Filter tags that match user input tag
    $self->_filter;

    # Step 2: Remove the tag from the sequence and quality strings
    $self->_remove;
    unlink("$destination_directory/filter.fastq");

    #Step 3: Map file to reference
    $self->_map;
    unlink("$destination_directory/tags_removed.fastq");

    #Step 3.5: Convert output from SAM to BAM
    $self->_sam2bam;
    unlink("$destination_directory/mapped.sam");
    unlink("$destination_directory/ref.index.sma");
    unlink("$destination_directory/ref.index.smi");

    #Step 4: Generate plot
    $self->_make_plot;
    unlink("$destination_directory/mapped.bam");

    return 1;
}

sub _filter {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname();
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
    my $destination_directory = $self->destination->dirname();
    my $tag                   = $self->tag;

    my $rm_tags = Bio::Tradis::RemoveTags->new(
        fastqfile => "$destination_directory/filter.fastq",
        tag       => $tag,
        outfile   => "$destination_directory/tags_removed.fastq"
    )->remove_tags;
}

sub _map {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname();
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
    my $destination_directory = $self->destination->dirname();

    system(
"samtools view -b -o $destination_directory/mapped.bam -S $destination_directory/mapped.sam"
    );
	return 1;
}

sub _make_plot {
    my ($self)                = @_;
    my $destination_directory = $self->destination->dirname();
    my $ref                   = $self->reference;
    my $outfile               = $self->outfile;

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile => "$destination_directory/mapped.bam",
        reference  => "$ref",
        outfile    => "$outfile"
    )->plot;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
