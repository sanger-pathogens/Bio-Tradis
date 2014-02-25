package Bio::Tradis::CommandLine::RunMapping;

# ABSTRACT: Perform mapping

=head1 SYNOPSIS

Takes a reference genome and indexes it.
Maps given fastq files to ref.

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::Map;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'reference'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'refname' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'ref.index' );
has 'outfile' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'mapped.sam' );
has 'smalt_k' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_s' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_y' => ( is => 'rw', isa => 'Maybe[Num]', required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $ref, $refname, $outfile, $smalt_k, $smalt_s, $smalt_y, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s'   => \$fastqfile,
        'r|reference=s'   => \$ref,
        'rn|refname=s'    => \$refname,
        'o|outfile=s'     => \$outfile,
	'sk|smalt_k=i'    => \$smalt_k,
	'ss|smalt_s=i'    => \$smalt_s,
	'sy|smalt_y=f'    => \$smalt_y,
        'h|help'          => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->reference( abs_path($ref) )       if ( defined($ref) );
    $self->refname($refname)                 if ( defined($refname) );
    $self->outfile( abs_path($outfile) )     if ( defined($outfile) );
    $self->smalt_k( $smalt_k )               if ( defined($smalt_k) );
    $self->smalt_s( $smalt_s )               if ( defined($smalt_s) );
    $self->smalt_y( $smalt_y )               if ( defined($smalt_y) );
    $self->help($help)                       if ( defined($help) );

	# print usage text if required parameters are not present
	($fastqfile && $ref) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {
    #if ( scalar( @{ $self->args } ) == 0 ) {
          $self->usage_text;
    }

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => $self->fastqfile,
        reference => $self->reference,
        refname   => $self->refname,
        outfile   => $self->outfile,
	smalt_k   => $self->smalt_k,
	smalt_s   => $self->smalt_s,
	smalt_y   => $self->smalt_y
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

sub usage_text {
      print <<USAGE;
Indexes the reference genome and maps the given fastq file.
-k and -s options for indexing are calculated for the length of
the read as follows unless otherwise specified ( --smalt_k & 
--smalt_s options )
Read length    | k  |  s
---------------+----+-----
<70            | 13 |  4
>70 & <100     | 13 |  6
>100           | 20 |  13

Usage: run_mapping -f file.fastq -r ref.fa [options]

Options:
-f        : fastq file to map
-r        : reference in fasta format
-rn       : reference index name (optional. default: ref.index)
-o        : mapped SAM output name (optional. default: mapped.sam)
--smalt_k : custom k-mer value for SMALT mapping
--smalt_s : custom step size for SMALT mapping

USAGE
      exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
