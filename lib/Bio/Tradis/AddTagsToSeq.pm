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
    print STDERR "Reading BAM header\n";
    system("samtools view -H $filename > tmp.sam");
    open( TMPFILE, '>>tmp.sam' );

    #open BAM file in SAM format using samtools
    print STDERR "Reading BAM file\n";
    my @field_order = (
        "QNAME", "FLAG",  "RNAME", "POS", "MAPQ", "CIGAR",
        "RNEXT", "PNEXT", "TLEN",  "SEQ", "QUAL", "X0",
        "X1",    "BC",    "MD",    "RG",  "XG",   "XM",
        "XO",    "QT",    "XT",    "tq",  "tr"
    );

    while ( $pars->next_read ) {
        my $read_info = $pars->read_info;
        my $line      = ${$read_info}{READ};

        # get tags, seq, qual and cigar str
        my $trtag = ${$read_info}{tr};
        my $tqtag = ${$read_info}{tq};

        my $seq_tagged   = ${$read_info}{SEQ};
        my $qual_tagged  = ${$read_info}{QUAL};
        my $cigar_update = ${$read_info}{CIGAR};

        #Check if seq is mapped & rev complement. If so, reformat.
        my $mapped = $pars->is_mapped;
        my $rev    = $pars->is_reverse;
        if ( $mapped && $rev ) {

            # The transposon is not reverse complimented but the genomic read is

            # reverse the genomic quality scores.
            $qual_tagged = reverse($qual_tagged);

            # Add the transposon quality score on the beginning
            $qual_tagged = $tqtag . $qual_tagged;

            # Reverse the whole quality string.
            $qual_tagged = reverse($qual_tagged);

            # Reverse the genomic sequence
            my $genomic_seq_obj =
              Bio::Seq->new( -seq => $seq_tagged, -alphabet => 'dna' );
            my $reversed_genomic_seq_obj = $genomic_seq_obj->revcom;

            # Add on the tag sequence
            $seq_tagged = $trtag . $reversed_genomic_seq_obj->seq;

  # Reverse the tag+genomic sequence to get it back into the correct orentation.
            my $genomic_and_tag_seq_obj =
              Bio::Seq->new( -seq => $seq_tagged, -alphabet => 'dna' );
            $seq_tagged = $genomic_and_tag_seq_obj->revcom->seq;

        }
        else {
            $seq_tagged  = $trtag . $seq_tagged;
            $qual_tagged = $tqtag . $qual_tagged;
        }

        if ($mapped) {
            my $cigar = length($seq_tagged);
            $cigar_update = $cigar . 'M';
        }
        else {
            $cigar_update = '*';
        }

        # replace updated fields and print to TMPFILE
        my @cols = split( " ", $line );
        $cols[5]  = $cigar_update;
        $cols[9]  = $seq_tagged;
        $cols[10] = $qual_tagged;

        print TMPFILE join( "\t", @cols ) . "\n";
    }

    close TMPFILE;

    #convert tmp.sam to bam
    print STDERR "Convert SAM to BAM\n";
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
