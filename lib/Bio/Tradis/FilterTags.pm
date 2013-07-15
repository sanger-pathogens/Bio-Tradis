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
use Bio::Tradis::Parser::Fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'tag'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'mismatch'  => ( is => 'rw', isa => 'Int', required => 0 );
has 'outfile'   => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my ($self) = @_;
        my $o = $self->fastqfile;
        $o =~ s/\.fastq/\.tag\.fastq/;
        return $o;
    }
);
has '_currentread' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 0,
    writer   => '_set_currentread'
);

sub filter_tags {
    my ($self)  = @_;
    my $tag     = uc( $self->tag );
    my $outfile = $self->outfile;

    #set up fastq parser
    my $filename = $self->fastqfile;
    my $pars = Bio::Tradis::Parser::Fastq->new( file => $filename );

    open( OUTFILE, ">$outfile" );

    while ( $pars->next_read ) {
        my @read        = $pars->read_info;
		$self->_set_currentread(\@read);
        my $id          = $read[0];
        my $seq_string  = $read[1];
        my $qual_string = $read[2];

        my $print_out = 0;
        if ( $self->mismatch == 0 ) {
            if ( $seq_string =~ /^$tag/ ) {
                $print_out = 1;
            }
        }
        else {
            my $mm = $self->_tag_mismatch($seq_string);
            if ( $mm <= $self->mismatch ) {
                $print_out = 1;
            }
        }

        if ($print_out) {
            print OUTFILE "\@$id\n";
            print OUTFILE $seq_string . "\n+\n";
            print OUTFILE $qual_string . "\n";
        }
    }
    close OUTFILE;
    return 1;
}

sub _tag_mismatch {
    my ($self) = @_;
    my $tag_len = length( $self->tag );
	my $seq_string = ${$self->_currentread}[1];

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
