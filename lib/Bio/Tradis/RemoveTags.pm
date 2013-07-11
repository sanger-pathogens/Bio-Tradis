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
use Bio::Tradis::Parser::Fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'tag'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default => sub { 
		my ($self) = @_;
		my $o = $self->bamfile; 
		$o =~ s/\.fastq/\.rmtag\.fastq/; 
		return $o; 
	}
);
sub remove_tags {
    my ($self) = @_;
    my $tag = uc( $self->tag );
	my $outfile = $self->outfile;

    #set up fastq parser
    my $filename = $self->fastqfile;
    my $pars = Bio::Tradis::Parser::Fastq->new( file => $filename );

    # create file handle for output
    open( OUTFILE, ">$outfile" );

    # loop through fastq
    while ( $pars->next_read ) {
        my @read        = $pars->read_info;
        my $id          = $read[0];
        my $seq_string  = $read[1];
        my $qual_string = $read[2];

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
