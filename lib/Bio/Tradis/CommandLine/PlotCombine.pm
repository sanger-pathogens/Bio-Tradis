package Bio::Tradis::CommandLine::PlotCombine;

# ABSTRACT: Combine multiple plotfiles and generate updated statistics for the combined files

=head1 SYNOPSIS

Takes a tab-delimited file with an ID as the first column followed by 
a list of plotfiles to combine per row. The ID will be used to name the new
plotfile and as an identifier in the stats file, so ensure these are unique.

For example, an input file named plots_to_combine.txt:

   tradis1	plot1.1.gz	plot1.2.gz plot1.3.gz
   tradis2 plot2.1.gz	plot2.2.gz
   tradis3	plot3.1.gz	plot3.2.gz plot3.3.gz	plot3.4.gz

will produce:

=over

=item 1. a directory named combined with 3 files - tradis1.insertion_site_plot.gz,
tradis2.insertion_site_plot.gz, tradis3.insertion_site_plot.gz

=item 2. a stats file named plots_to_combine.stats

=back

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::CombinePlots;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'plotfile'    => ( is => 'rw', isa => 'Str',      required => 0 );
has 'output_dir'  => ( is => 'rw', isa => 'Str',      default  => 'combined' );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $plotfile, $output_dir, $help );

    GetOptionsFromArray(
        $self->args,
        'p|plotfile=s' => \$plotfile,
        'o|output_dir' => \$output_dir,
        'h|help'       => \$help
    );

    $self->plotfile( abs_path($plotfile) ) if ( defined($plotfile) );
    $self->help($help) if ( defined($help) );

    # print usage text if required parameters are not present
    ($plotfile) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    $self->usage_text if ( defined( $self->help ) );

    Bio::Tradis::CombinePlots->new( 
        plotfile     => $self->plotfile, 
        combined_dir => $self->output_dir,
    )->combine;
}

sub usage_text {
    print <<USAGE;
Combine multiple plotfiles and generate updated statistics for the combined
files. Takes a tab-delimited file with an ID as the first column followed by 
a list of plotfiles to combine per row. The ID will be used to name the new
plotfile and as an identifier in the stats file, so ensure these are unique.

For example, an input file named plots_to_combine.txt:

tradis1	plot1.1.gz	plot1.2.gz plot1.3.gz
tradis2 plot2.1.gz	plot2.2.gz
tradis3	plot3.1.gz	plot3.2.gz plot3.3.gz	plot3.4.gz

will produce 
1. a directory named combined with 3 files - tradis1.insertion_site_plot.gz,
tradis2.insertion_site_plot.gz, tradis3.insertion_site_plot.gz
2. a stats file named plots_to_combine.stats

Usage: combine_tradis_plots -p plots.txt

Options:
-p|plotfile   : file with plots to be combined
-o|output_dir : name of directory for output (default: combined)

USAGE
    exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
