package Bio::Tradis::CommandLine::FilterFastqTags;

# ABSTRACT: Remove given tags from the start of the sequence

=head1 SYNOPSIS

Removes tags from the sequence and quality strings

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::FilterTags;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'tag'         => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $tag, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s' => \$fastqfile,
        't|tag=s'       => \$tag,
        'o|outfile=s'   => \$outfile,
        'h|help'        => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->tag($tag)                         if ( defined($tag) );
    $self->outfile( abs_path($outfile) )     if ( defined($outfile) );
    $self->help($help)                       if ( defined($help) );

}

sub run {
    my ($self) = @_;
    if ( defined( $self->help ) ) {
        print "Help here";
    }

    my $tag_filter = Bio::Tradis::FilterTags->new(
        fastqfile => $self->fastqfile,
        tag       => $self->tag,
        outfile   => $self->outfile
    );
    $tag_filter->filter_tags;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
