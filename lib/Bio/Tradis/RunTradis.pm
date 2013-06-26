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

has 'fastqfile'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'fastqfile2' => ( is => 'rw', isa => 'Str', required => 0 );
has 'tag'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'reference'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile'    => ( is => 'rw', isa => 'Str', required => 0 );
has 'destination' =>
  ( is => 'ro', isa => 'File::Temp', builder => '_build_destination' );

sub _build_destination {
    File::Temp->newdir( CLEANUP => 1 );
}

sub run_tradis {
    my ($self)                = @_;
    my $fqfile                = $self->fastqfile;
    my $tag                   = $self->tag;
    my $ref                   = $self->reference;
    my $destination_directory = $self->destination->dirname();

    # Step 1: Filter tags that match user input tag
    my $filter = Bio::Tradis::FilterTags->new(
        fastqfile => $fqfile,
        tag       => $tag,
        outfile   => "$destination_directory/filter.fastq"
    )->filter_tags;

    # Step 2: Remove the tag from the sequence and quality strings
    my $rm_tags = Bio::Tradis::RemoveTags->new(
        fastqfile => "$destination_directory/filter.fastq",
        tag       => $tag,
        outfile   => "$destination_directory/tags_removed.fastq"
    )->remove_tags;
    system("rm $destination_directory/filter.fastq");

    #Step 3: Map file to reference
    my $mapping = Bio::Tradis::Map->new(
        fastqfile => "$destination_directory/tags_removed.fastq",
        reference => "$ref",
        refname   => "$destination_directory/ref.index",
        outfile   => "$destination_directory/mapped.sam"
    );
    system("rm $destination_directory/tags_removed.fastq");

    #Step 3.5: Convert output from SAM to BAM
    system(
		"samtools -b -o $destination_directory/mapped.bam -S $destination_directory/mapped.sam"
    );
	system("rm $destination_directory/mapped.sam");
	system("rm $destination_directory/ref.index*");

    #Step 4: Generate plots
    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile => "$destination_directory/mapped.bam",
        reference  => "$ref",
        outfile    => "$destination_directory/currentplot"
    )->plot;
    system("rm $destination_directory/mapped.bam");

    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
