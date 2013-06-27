package Bio::Tradis::CommandLine::TradisAnalysis;

# ABSTRACT: Perform full tradis analysis

=head1 SYNOPSIS

Takes a fastq, reference and a tag and generates insertion
site plots for use in Artemis

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::RunTradis;

has 'args'        => ( is => 'ro', isa => 'ArrayRef',   required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',        required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',        required => 0 );
has 'fastqfile2'  => ( is => 'rw', isa => 'Maybe[Str]', required => 0 );
has 'tag'         => ( is => 'rw', isa => 'Str',        required => 0 );
has 'reference'   => ( is => 'rw', isa => 'Str',        required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',       required => 0 );
has 'outfile' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'tradis.plot' );
has 'destination' => (
    is       => 'rw',
    isa      => 'File::Temp::Dir',
    required => 0
);

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $fastqfile2, $tag, $ref, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s'   => \$fastqfile,
        'f2|fastqfile2=s' => \$fastqfile2,
        't|tag=s'         => \$tag,
        'r|reference=s'   => \$ref,
        'o|outfile=s'     => \$outfile,
        'h|help'          => \$help
    );

    $self->fastqfile( abs_path($fastqfile) )   if ( defined($fastqfile) );
    $self->fastqfile2( abs_path($fastqfile2) ) if ( defined($fastqfile2) );
    $self->tag( uc($tag) )                     if ( defined($tag) );
    $self->reference( abs_path($ref) )         if ( defined($ref) );
    $self->outfile( abs_path($outfile) )       if ( defined($outfile) );
    $self->help($help)                         if ( defined($help) );

}

sub run {
    my ($self) = @_;
    if ( defined( $self->help ) ) {
        print "Help here";
    }

    my $analysis = Bio::Tradis::RunTradis->new(
        fastqfile  => $self->fastqfile,
        fastqfile2 => $self->fastqfile2,
        tag        => $self->tag,
        reference  => $self->reference,
        outfile    => $self->outfile
    );
    $analysis->run_tradis;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
