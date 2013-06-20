package Bio::Tradis::FilterTags;

# ABSTRACT: Filter tags in a fastq file

=head1 SYNOPSIS

Reads in a fastq file with tradis tags already attached to the start of the sequence
Filters reads that contain the provided tag
Outputs a file *.tag.fastq unless an out file is specified

   use Bio::Tradis::FilterTags;
   
   my $pipeline = Bio::Tradis::FilterTags->new(fastqfile => 'abc', tag => 'abc');
   $pipeline->filter_tags();

=cut

use Moose;
use VertRes::Parser::fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'tag'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile'   => ( is => 'rw', isa => 'Str', required => 0 );

sub filter_tags {
    my ($self) = @_;
    my $tag = $self->tag;

    #set up fastq parser
    my $filename      = $self->fastqfile;
    my $pars          = VertRes::Parser::fastq->new( file => $filename );
    my $result_holder = $pars->result_holder();

    my $outfile = $filename;
    if ( defined( $self->outfile ) ) {
        $outfile = $self->outfile;
    }
    else {
        $outfile =~ s/\.fastq/\.tag\.fastq/;
    }
    open( OUTFILE, ">$outfile" );

    while ( $pars->next_result() ) {
        my $id          = $result_holder->[0];
        my $seq_string  = $result_holder->[1];
        my $qual_string = $result_holder->[2];

        if ( $seq_string =~ /^$tag/ ) {
            print OUTFILE "\@$id\n";
            print OUTFILE $seq_string . "\n+\n";
            print OUTFILE $qual_string . "\n";
        }
    }
	close OUTFILE;
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
