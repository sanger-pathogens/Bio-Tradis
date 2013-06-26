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
  ( is => 'rw', isa => 'Maybe[Str]', required => 0, default => 'mapped.sam' );

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $ref, $refname, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s' => \$fastqfile,
        'r|reference=s' => \$ref,
        'rn|refname=s'  => \$refname,
        'o|outfile=s'   => \$outfile,
        'h|help'        => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->reference( abs_path($ref) )       if ( defined($ref) );
    $self->refname($refname)                 if ( defined($refname) );
    $self->outfile( abs_path($outfile) )     if ( defined($outfile) );
    $self->help($help)                       if ( defined($help) );

}

sub run {
    my ($self) = @_;
    if ( defined( $self->help ) ) {
        print "Help here";
    }

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => $self->fastqfile,
        reference => $self->reference,
        refname   => $self->refname,
        outfile   => $self->outfile
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
