package Bio::Tradis::CommandLine::AddTags;

# ABSTRACT: Add given tags to the start of the sequence

=head1 SYNOPSIS

Adds given tags to the start of the sequence

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::AddTagsToSeq;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'bamfile'     => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $bamfile, $outfile, $help );

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

    my $tagadd = Bio::Tradis::AddTagsToSeq->new(
        bamfile => $self->bamfile,
        outfile => $self->outfile
    );
    $tagadd->add_tags_to_seq;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
