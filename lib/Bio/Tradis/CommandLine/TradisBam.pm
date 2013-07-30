package Bio::Tradis::CommandLine::TradisBam;

# ABSTRACT: Adds tags to sequences if tags are present

=head1 SYNOPSIS

Checks for tradis tags in the BAM and outputs processed TraDIS BAM file
with tags attached

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::DetectTags;
use Bio::Tradis::AddTagsToSeq;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'bamfile'     => ( is => 'rw', isa => 'Str',      required => 1 );
has 'outfile'     => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my $o = $self->bamfile;
        $o =~ s/\.bam/\.tr\.bam/;
        return $o;
    }
);
has 'help' => ( is => 'rw', isa => 'Bool', required => 0 );

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

	# print usage text if required parameters are not present
	($bamfile) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {
    #if ( scalar( @{ $self->args } ) == 0 ) {
        $self->usage_text;
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

sub usage_text {
    print <<USAGE;
Checks for tradis tags in the BAM and outputs processed TraDIS BAM file
with tags attached

Usage: bam_to_tradis_bam -b file.bam [options]

Options:
-b  : bam file
-o  : output BAM name (optional. default: <file>.tr.bam)

USAGE
    exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
