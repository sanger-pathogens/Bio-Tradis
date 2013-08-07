package Bio::Tradis::Map;

# ABSTRACT: Perform mapping

=head1 SYNOPSIS

Takes a reference genome and indexes it.
Maps given fastq files to ref.

   use Bio::Tradis::Map;
   
   my $pipeline = Bio::Tradis::Map->new(fastqfile => 'abc', reference => 'abc');
   $pipeline->index_ref();
   $pipeline->do_mapping();

=head1 PARAMETERS

=head2 Required

=over
=item * C<fastqfile> - path to/name of file containing reads to map to the reference
=item * C<reference> - path to/name of reference genome in fasta format (.fa)
=back

=head2 Optional

=over
=item * C<refname> - name to assign to the reference index files. Default = ref.index
=item * C<outfile> -  name to assign to the mapped SAM file. Default = mapped.sam
=back

=head1 METHODS

=over
=item * C<index_ref> - create index files of the reference genome. These are required
			for the mapping step. Only skip this step if index files already
			exist. -k and -s options for referencing are calculated based
			on the length of the reads being mapped as per table:
=begin html
<table>
<tr><th>Read length</th><th>k</th><th>s</th></tr>
<tr><td><70</td><td>13</td><td>4<td></tr>
<tr><td>>70 and <100</td><td>13</td><td>6<td></tr>
<tr><td>>100</td><td>20</td><td>6<td></tr>
</table>
=end html
=item * C<do_mapping> - map C<fastqfile> to C<reference>. Options used for mapping are: C<-r -1 -x -y 0.96>
=back

For more information on the mapping and indexing options discussed here, see the L<SMALT manual|ftp://ftp.sanger.ac.uk/pub4/resources/software/smalt/smalt-manual-0.7.4.pdf>

=cut

use Moose;
use Bio::Tradis::Parser::Fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'reference' => ( is => 'rw', isa => 'Str', required => 1 );
has 'refname' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'ref.index' );
has 'outfile' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'mapped.sam' );

sub index_ref {
    my ($self)  = @_;
    my $ref     = $self->reference;
    my $refname = $self->refname;

    # Calculate index parameters
    my $pars = Bio::Tradis::Parser::Fastq->new( file => $self->fastqfile );
    $pars->next_read;
    my @read = $pars->read_info;
    my ( $k, $s );
    ( $k, $s ) = ( 13, 4 );
    my $seq = $read[1];
    if ( length($seq) < 70 ) {
        ( $k, $s ) = ( 13, 4 );
    }
    elsif ( length($seq) > 70 && length($seq) < 100 ) {
        ( $k, $s ) = ( 13, 6 );
    }
    else {
        ( $k, $s ) = ( 20, 13 );
    }

    system("smalt index -k $k -s $s $refname $ref");
    return 1;
}

sub do_mapping {
    my ($self)  = @_;
    my $fqfile  = $self->fastqfile;
    my $refname = $self->refname;
    my $outfile = $self->outfile;

    system("smalt map -x -r -1 -y 0.96 $refname $fqfile 1> $outfile  2> smalt.stderr");
	unlink('smalt.stderr');
	return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
