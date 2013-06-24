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
use VertRes::Parser::bam;

has 'bamfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' => ( is => 'rw', isa => 'Str', required => 0 );

sub add_tags_to_seq {
    my ($self) = @_;

    #set up BAM parser
    my $filename      = $self->bamfile;
    my $pars          = VertRes::Parser::bam->new( file => $filename );
    my $result_holder = $pars->result_holder();

    #open temp file in SAM format and output headers from current BAM to it
    `samtools view -H $filename > tmp.sam`;
    open( TMPFILE, '>>tmp.sam' );

    #set up parser to capture flags and tags
    $pars->get_fields( 'FLAG', 'tr', 'tq' );

    #open BAM file in SAM format using samtools
    my @bam = split( "\n", `samtools view $filename` );
    my $c = 0;
    while ( $pars->next_result() ) {
        my $line = $bam[$c];
        $c++;

        #split current line into columns and get tags
        my @cols  = split( " ", $line );
        my $trtag = $result_holder->{tr};
        my $tqtag = $result_holder->{tq};

		#replace CIGAR string with unmapped
		$cols[5] = '*';

        #Check if seq is mapped & rev complement. If so, reformat.
        my $flag   = $result_holder->{FLAG};
        my $mapped = $pars->is_mapped($flag);
        my $rev    = $pars->is_reverse_strand($flag);
        if ( $mapped && $rev ) {
            # The transposon is not reverse complimented but the genomic read is
            
            # reverse the genomic quality scores.
            $cols[10] = reverse($cols[10]);
            # Add the transposon quality score on the beginning
            $cols[10] = $tqtag . $cols[10];
            # Reverse the whole quality string.
            $cols[10] = reverse($cols[10]);
            # Reverse the genomic sequence
            my $genomic_seq_obj = Bio::Seq->new( -seq => $cols[9], -alphabet => 'dna' );
            my $reversed_genomic_seq_obj = $genomic_seq_obj->revcom;
            
            # Add on the tag sequence
            $cols[9]  = $trtag . $reversed_genomic_seq_obj->seq;
            # Reverse the tag+genomic sequence to get it back into the correct orentation.
            my $genomic_and_tag_seq_obj = Bio::Seq->new( -seq => $cols[9], -alphabet => 'dna' );
            $cols[9] = $genomic_and_tag_seq_obj->revcom->seq;
            
        }
        else {
            $cols[9]  = $trtag . $cols[9];
            $cols[10] = $tqtag . $cols[10];
        }

        print TMPFILE join( "\t", @cols ) . "\n";
    }

	close TMPFILE;

    #create new filename for output and convert tmp.sam to bam
    my $outfile = $filename;
    if ( defined( $self->outfile ) ) {
        $outfile = $self->outfile;
    }
    else {
        $outfile =~ s/\.bam/\.tr\.bam/;
    }
    `samtools view -S -b -o $outfile tmp.sam`;

    if($self->_number_of_lines_in_bam_file($outfile) != $self->_number_of_lines_in_bam_file($filename ))
    {
      die "The number of lines in the input and output files dont match so somethings gone wrong\n";
    }

    #remove tmp file
    `rm tmp.sam`;
	return 1;
}

sub _number_of_lines_in_bam_file
{
  my ($self, $filename) = @_;
  open( my $fh, '-|',   "samtools view $filename | wc -l") or die "Couldnt open file :". $filename;
  my $number_of_lines_in_file = <$fh>;
  $number_of_lines_in_file =~ s!\W!!gi;
  return $number_of_lines_in_file;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
