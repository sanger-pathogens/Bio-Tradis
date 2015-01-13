package Bio::Tradis::AddTagsToSeq;

# ABSTRACT: Takes a BAM file and creates a new BAM with tr and tq tags added to the sequence and quality strings.

=head1 NAME

Bio::Tradis::AddTagsToSeq

=head1 SYNOPSIS

Bio::Tradis::AddTagsToSeq parses BAM files, adds given tags to the start of the sequence and creates temporary SAM file,
which is then converted to BAM

   use Bio::Tradis::AddTagsToSeq;
   
   my $pipeline = Bio::Tradis::AddTagsToSeq->new(bamfile => 'abc');
   $pipeline->add_tags_to_seq();

=head1 PARAMETERS

=head2 Required

C<bamfile> - path to/name of file containing reads and tags

=head2 Optional

C<outfile> - name to assign to output BAM. Defaults to C<file.tr.bam> for an input file named C<file.bam>

=head1 METHODS

C<add_tags_to_seq> - add TraDIS tags to reads. For unmapped reads, the tag
				  is added to the start of the read sequence and quality
				  strings. For reads where the flag indicates that it is
				  mapped and reverse complemented, the reverse complemented
				  tags are added to the end of the read strings.
				  This is because many conversion tools (e.g. picard) takes
				  the read orientation into account and will re-reverse the
				  mapped/rev comp reads during conversion, leaving all tags
				  in the correct orientation at the start of the sequences
				  in the resulting FastQ file.

=cut

use Moose;
use Bio::Seq;
use Bio::Tradis::Parser::Bam;
use File::Basename;

no warnings qw(uninitialized);

has 'verbose' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'samtools_exec' => ( is => 'rw', isa => 'Str', default => 'samtools' );
has 'bamfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my ($self) = @_;
        my $o = $self->bamfile;
        $o =~ s/\.bam/\.tr\.bam/;
        $o =~ s/\.cram/\.tr\.cram/;
        return $o;
    }
);

has '_file_extension' => ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build__file_extension' );
has 'extension_to_output_switch' => ( is => 'rw', isa => 'HashRef', default => sub{ {cram => '-C', bam => '-b'} } );

sub _build__file_extension
{
  my ($self) = @_;
  my($filename, $dirs, $suffix) = fileparse($self->bamfile,qr/[^.]*/);
  return lc($suffix);
}

sub add_tags_to_seq {
    my ($self) = @_;

    #set up BAM parser
    my $filename = $self->bamfile;
    my $outfile   = $self->outfile;

    #open temp file in SAM format and output headers from current BAM to it
    print STDERR "Reading ".uc($self->_file_extension)." header\n" if($self->verbose);
    system($self->samtools_exec." view -H $filename > tmp.sam");
    open( TMPFILE, '>>tmp.sam' );

    #open BAM file
    print STDERR "Reading ".uc($self->_file_extension)." file\n" if($self->verbose);
    my $pars = Bio::Tradis::Parser::Bam->new( file => $filename, samtools_exec => $self->samtools_exec );
    my $read_info = $pars->read_info;

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
			#print STDERR "$line\n" if(!defined($tqtag));
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
	$pars->close_file_handle;
    close TMPFILE;

    #convert tmp.sam to bam
    print STDERR "Convert SAM to ".uc($self->_file_extension)."\n" if($self->verbose);
    
    
    system($self->samtools_exec." view -h -S ".$self->_output_switch." -o $outfile tmp.sam");

    if ( $self->_number_of_lines_in_bam_file($outfile) !=
        $self->_number_of_lines_in_bam_file($filename) )
    {
        die
"The number of lines in the input and output files don't match, so something's gone wrong\n";
    }

    #remove tmp file
    unlink("tmp.sam");
    return 1;
}

sub _output_switch
{
  my ( $self ) = @_;
  if(defined($self->extension_to_output_switch->{$self->_file_extension}))
  {
    return $self->extension_to_output_switch->{$self->_file_extension};
  }
  else
  {
    return '';
  }
}

sub _number_of_lines_in_bam_file {
    my ( $self, $filename ) = @_;
    open( my $fh, '-|', $self->samtools_exec." view $filename | wc -l" )
      or die "Couldn't open file :" . $filename;
    my $number_of_lines_in_file = <$fh>;
    $number_of_lines_in_file =~ s!\W!!gi;
    return $number_of_lines_in_file;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
