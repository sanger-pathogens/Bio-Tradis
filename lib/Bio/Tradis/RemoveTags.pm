package Bio::Tradis::RemoveTags;

# ABSTRACT: Remove tags from seqs a fastq file

=head1 SYNOPSIS

Reads in a fastq file with tradis tags already attached to the start of the sequence
Removes tags from the sequence and quality strings
Outputs a file *.rmtag.fastq unless an out file is specified

   use Bio::Tradis::RemoveTags;
   
   my $pipeline = Bio::Tradis::RemoveTags->new(fastqfile => 'abc', tag => 'abc');
   $pipeline->remove_tags();

=head1 PARAMETERS

=head2 Required

=over
=item * C<fastqfile> - path to/name of file to filter
=item * C<tag> - TraDIS tag to remove
=back

=head2 Optional

=over
=item * C<mismatch> - number of mismatches to allow when removing the tag. Default = 0
=item * C<outfile> - defaults to C<file.rmtag.fastq> for and input file named C<file.fastq>
=back

=head1 METHODS
C<remove_tags> - output all reads with the tags removed to C<outfile>

=cut

use Moose;
use Bio::Tradis::Parser::Fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'tag'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'mismatch'  => ( is => 'rw', isa => 'Int', required => 0 );
has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my ($self) = @_;
        my $o = $self->bamfile;
        $o =~ s/\.fastq/\.rmtag\.fastq/;
        return $o;
    }
);

sub remove_tags {
    my ($self)  = @_;
    my $tag     = uc( $self->tag );
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
        my $rm = 0;
        if ( $self->mismatch == 0 ) {
            if ( $seq_string =~ m/^$tag/ ) { $rm = 1; }
        }
        else {
            my $mm = $self->_tag_mismatch($seq_string);
            if ( $mm <= $self->mismatch ) { $rm = 1; }
        }

        if ($rm) {
            my $l = length($tag);
            $seq_string  = substr( $seq_string,  $l );
            $qual_string = substr( $qual_string, $l );
        }

        print OUTFILE "\@$id\n";
        print OUTFILE $seq_string . "\n+\n";
        print OUTFILE $qual_string . "\n";
    }
    close OUTFILE;
    return 1;
}

sub _tag_mismatch {
    my ( $self, $seq_string ) = @_;
    my $tag_len = length( $self->tag );

    my @tag = split( "", $self->tag );
    my @seq = split( "", substr( $seq_string, 0, $tag_len ) );
    my $mismatches = 0;
    foreach my $i ( 0 .. ( $tag_len - 1 ) ) {
        if ( $tag[$i] ne $seq[$i] ) {
            $mismatches++;
        }
    }
    return $mismatches;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
