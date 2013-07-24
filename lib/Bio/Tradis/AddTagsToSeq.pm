package Bio::Tradis::AddTagsToSeq;

# ABSTRACT: Add tags to the start of the sequences

=head1 SYNOPSIS

Parses BAM files, adds given tags to the start of the sequence and creates temporary SAM file. 
Then converts to BAM and removes the tmp SAM file.

   use Bio::Tradis::AddTagsToSeq;
   
   my $pipeline = Bio::Tradis::AddTagsToSeq->new(bamfile => 'abc');
   $pipeline->add_tags_to_seq();

=cut

use Moose;
use Bio::Seq;
use Bio::Tradis::Parser::Bam;

has 'bamfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my ($self) = @_;
        my $o = $self->bamfile;
        $o =~ s/\.bam/\.tr\.bam/;
        return $o;
    }
);

sub add_tags_to_seq {
    my ($self) = @_;

    #set up BAM parser
    my $filename  = $self->bamfile;
    my $pars      = Bio::Tradis::Parser::Bam->new( file => $filename );
    my $read_info = $pars->read_info;
    my $outfile   = $self->outfile;

    #open temp file in SAM format and output headers from current BAM to it
    system("samtools view -H $filename > tmp.sam");
    open( TMPFILE, '>>tmp.sam' );

    #open BAM file in SAM format using samtools
    open( my $bam, "samtools view $filename |" );

    while ( $pars->next_read ) {
        my $line      = <$bam>;
        my $read_info = $pars->read_info;

        #split current line into columns and get tags
        my @cols  = split( " ", $line );
        my $trtag = ${$read_info}{tr};
        my $tqtag = ${$read_info}{tq};

        #Check if seq is mapped & rev complement. If so, reformat.
        my $mapped = $pars->is_mapped;
        my $rev    = $pars->is_reverse;
        if ( $mapped && $rev ) {

            # The transposon is not reverse complimented but the genomic read is

            # reverse the genomic quality scores.
            $cols[10] = reverse( $cols[10] );

            # Add the transposon quality score on the beginning
            $cols[10] = $tqtag . $cols[10];

            # Reverse the whole quality string.
            $cols[10] = reverse( $cols[10] );

            # Reverse the genomic sequence
            my $genomic_seq_obj =
              Bio::Seq->new( -seq => $cols[9], -alphabet => 'dna' );
            my $reversed_genomic_seq_obj = $genomic_seq_obj->revcom;

            # Add on the tag sequence
            $cols[9] = $trtag . $reversed_genomic_seq_obj->seq;

  # Reverse the tag+genomic sequence to get it back into the correct orentation.
            my $genomic_and_tag_seq_obj =
              Bio::Seq->new( -seq => $cols[9], -alphabet => 'dna' );
            $cols[9] = $genomic_and_tag_seq_obj->revcom->seq;

        }
        else {
            $cols[9]  = $trtag . $cols[9];
            $cols[10] = $tqtag . $cols[10];
        }

        if ($mapped) {
            my $cigar = length( $cols[9] );
            $cols[5] = $cigar . 'M';
        }
        else {
            $cols[5] = '*';
        }

        print TMPFILE join( "\t", @cols ) . "\n";
    }

    close TMPFILE;

    #convert tmp.sam to bam
    system("samtools view -S -b -o $outfile tmp.sam");

    if ( $self->_number_of_lines_in_bam_file($outfile) !=
        $self->_number_of_lines_in_bam_file($filename) )
    {
        die
"The number of lines in the input and output files dont match so somethings gone wrong\n";
    }

    #remove tmp file
    unlink("tmp.sam");
    return 1;
}

sub _number_of_lines_in_bam_file {
    my ( $self, $filename ) = @_;
    open( my $fh, '-|', "samtools view $filename | wc -l" )
      or die "Couldnt open file :" . $filename;
    my $number_of_lines_in_file = <$fh>;
    $number_of_lines_in_file =~ s!\W!!gi;
    return $number_of_lines_in_file;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
