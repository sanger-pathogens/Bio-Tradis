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
has 'smalt_k' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_s' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_y' => ( is => 'rw', isa => 'Maybe[Num]', required => 0, default => 0.96 );

sub index_ref {
    my ($self)  = @_;
    my $ref     = $self->reference;
    my $refname = $self->refname;

    # Calculate index parameters
    my $pars = Bio::Tradis::Parser::Fastq->new( file => $self->fastqfile );
    $pars->next_read;
    my @read = $pars->read_info;
	my $read_len = length($read[1]);
    my ( $k, $s ) = $self->_calculate_index_parameters($read_len);

    my $cmd = "smalt index -k $k -s $s $refname $ref > /dev/null 2>&1";
    system($cmd);
    return $cmd;
}

sub _calculate_index_parameters {
	my ($self, $read_len)  = @_;
	my ( $k, $s );
	
	if( defined $self->smalt_k ){ $k = $self->smalt_k; }
	else{ $k = $self->_smalt_k_default($read_len); }
	
	if( defined $self->smalt_s ){ $s = $self->smalt_s; }
	else{ $s = $self->_smalt_s_default($read_len); }
	
	return ( $k, $s );
}

sub _smalt_k_default {
	my ($self, $read_len)  = @_;
	if($read_len < 100){ return 13; }
	else{ return 20; }
}

sub _smalt_s_default {
	my ( $self, $read_len )  = @_;
	if( $read_len < 70 ){ return 4; }
	elsif( $read_len > 100 ){ return 13; }
	else{ return 6; }
}

sub do_mapping {
    my ($self)  = @_;
    my $fqfile  = $self->fastqfile;
    my $refname = $self->refname;
    my $outfile = $self->outfile;
    my $y = $self->smalt_y;

    my $smalt = "smalt map -x -r -1 -y $y $refname $fqfile 1> $outfile  2> smalt.stderr";

    system($smalt);
    unlink('smalt.stderr');
    
    return $smalt;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
