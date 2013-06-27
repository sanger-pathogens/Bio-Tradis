package Bio::Tradis::CommandLine::PlotTradis;

# ABSTRACT: Generate plots as part of a tradis analysis

=head1 SYNOPSIS

Generate insertion plots for Artemis from a mapped fastq file and
a reference in GFF format

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::TradisPlot;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'mappedfile'  => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $mappedfile, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|mappedfile=s' => \$mappedfile,
        'o|outfile=s'    => \$outfile,
        'h|help'         => \$help
    );

    $self->mappedfile( abs_path($mappedfile) ) if ( defined($mappedfile) );
    $self->outfile( abs_path($outfile) )       if ( defined($outfile) );
    $self->help($help)                         if ( defined($help) );

}

sub run {
    my ($self) = @_;
    if ( defined( $self->help ) ) {
        print "Help here";
    }

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile => $self->mappedfile,
        outfile    => $self->outfile
    );
    $plot->plot;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
