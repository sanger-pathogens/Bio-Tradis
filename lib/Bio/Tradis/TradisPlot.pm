package Bio::Tradis::TradisPlot;

# ABSTRACT: Generate plots as part of a tradis analysis

=head1 SYNOPSIS

Generate insertion plots for Artemis from a mapped fastq file and a reference
in GFF format

   use Bio::Tradis::TradisPlot;
   
   my $pipeline = Bio::Tradis::TradisPlot->new(mappedfile => 'abc');
   $pipeline->plot();

=cut

use Moose;
use Bio::Tradis::Analysis::InsertSite;

has 'mappedfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' =>
  ( is => 'rw', isa => 'Str', required => 1, default => 'tradis.plot' );
has 'mapping_score' =>
  ( is => 'rw', isa => 'Int', required => 1, default => 30 );

sub plot {
    my ($self) = @_;

    Bio::Tradis::Analysis::InsertSite->new(
        filename             => $self->mappedfile,
        output_base_filename => $self->outfile,
        mapping_score        => $self->mapping_score
    )->create_plots;

    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
