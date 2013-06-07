package Bio::Tradis::CommandLine::TradisBam;

# ABSTRACT: Check for presence of tr tag in BAM file

=head1 SYNOPSIS

Output processed TraDIS BAM file

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::DetectTags;
use Bio::Tradis::AddTagsToSeq;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'bamfile'     => ( is => 'rw', isa => 'Str',      required => 1 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 1 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $bamfile, $help, $outfile );

    GetOptionsFromArray(
        $self->args,
        'b|bamfile=s' => \$bamfile,
        'o|outfile=s' => \$outfile,
        'h|help'      => \$help
    );

    $self->bamfile( abs_path($bamfile) ) if ( defined($bamfile) );
    $self->outfile( abs_path($outfile) ) if ( defined($outfile) );
    $self->help($help)                   if ( defined($help) );

}

sub run {
    my ($self) = @_;
    if ( defined( $self->help ) ) {
        print "Help here";
    }

    my $is_tradis =
      Bio::Tradis::DetectTags->new( bamfile => $self->bamfile )->tags_present;
    if ( defined($is_tradis) && $is_tradis == 1 ) {
        my $add_tag_obj = Bio::Tradis::AddTagsToSeq->new(
            bamfile => $self->bamfile,
            outfile => $self->outfile
        );
        $add_tag_obj->add_tags_to_seq;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
