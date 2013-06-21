package Bio::Tradis::RemoveTags;

# ABSTRACT: Remove tags from seqs a fastq file

=head1 SYNOPSIS

Reads in a fastq file with tradis tags already attached to the start of the sequence
Removes tags from the sequence and quality strings
Outputs a file *.rmtag.fastq unless an out file is specified

   use Bio::Tradis::RemoveTags;
   
   my $pipeline = Bio::Tradis::RemoveTags->new(fastqfile => 'abc', tag => 'abc');
   $pipeline->remove_tags();

=cut

use Moose;
use VertRes::Parser::fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'tag'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile'   => ( is => 'rw', isa => 'Str', required => 0 );

sub remove_tags {
    my ($self) = @_;
    my $tag = $self->tag;

    #set up fastq parser
    my $filename      = $self->fastqfile;
    my $pars          = VertRes::Parser::fastq->new( file => $filename );
    my $result_holder = $pars->result_holder();

    # create file handle for output
    my $outfile = $filename;
    if ( defined( $self->outfile ) ) {
        $outfile = $self->outfile;
    }
    else {
        $outfile =~ s/\.fastq/\.rmtag\.fastq/;
    }
    open( OUTFILE, ">$outfile" );

    # loop through fastq
    while ( $pars->next_result() ) {
        my $id          = $result_holder->[0];
        my $seq_string  = $result_holder->[1];
        my $qual_string = $result_holder->[2];

        # remove the tag
        my $l = length($tag);
        if ( $seq_string =~ m/^$tag/ ) {
            $seq_string =~ s/^$tag//;
            $qual_string = substr( $qual_string, $l );
        }

        print OUTFILE "\@$id\n";
        print OUTFILE $seq_string . "\n+\n";
        print OUTFILE $qual_string . "\n";
    }
	close OUTFILE;
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
