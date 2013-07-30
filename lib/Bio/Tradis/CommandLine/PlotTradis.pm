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
has 'mapping_score' => ( is => 'rw', isa => 'Int', required => 0, default => 30);
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0, default => 'tradis.plot' );

sub BUILD {
    my ($self) = @_;

    my ( $mappedfile, $outfile, $mapping_score, $help );

    GetOptionsFromArray(
        $self->args,
        'f|mappedfile=s' => \$mappedfile,
        'o|outfile=s'    => \$outfile,
        'm|mapping_score' => \$mapping_score,
        'h|help'         => \$help
    );

    $self->mappedfile( abs_path($mappedfile) ) if ( defined($mappedfile) );
    $self->outfile( abs_path($outfile) )       if ( defined($outfile) );
    $self->mapping_score($mapping_score)       if ( defined($mapping_score) );
    $self->help($help)                         if ( defined($help) );

	# print usage text if required parameters are not present
	($mappedfile) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {
    #if ( scalar( @{ $self->args } ) == 0 ) {
          $self->usage_text;
    }

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile => $self->mappedfile,
        outfile    => $self->outfile,
        mapping_score => $self->mapping_score
    );
    $plot->plot;
}

sub usage_text {
      print <<USAGE;
Create insertion site plot for Artemis

Usage: tradis_plot -f file.bam [options]

Options:
-f  : mapped, sorted bam file
-m	: mapping quality must be greater than X (optional. default: 30)
-o  : output base name for plot (optional. default: tradis.plot)

USAGE
      exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
