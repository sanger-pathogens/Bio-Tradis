package Bio::Tradis::DetectTags;

# ABSTRACT: Detect tr tags in BAM file

=head1 NAME

Bio::Tradis::DetectTags

=head1 SYNOPSIS

Detects presence of tr/tq tags in BAM files from Tradis analyses
   use Bio::Tradis::DetectTags;
   
   my $pipeline = Bio::Tradis::DetectTags->new(bamfile => 'abc');
   $pipeline->tags_present();

=head1 PARAMETERS

=head2 Required

C<bamfile> - path to/name of file to check

=head1 METHODS

C<tags_present> - returns true if TraDIS tags are detected in C<bamfile>

=cut

use Moose;
use Bio::DB::Sam;

has 'bamfile' => ( is => 'ro', isa => 'Str', required => 1 );

sub tags_present {
    my ($self) = @_;
    my $bam    = Bio::DB::Bam->open( $self->bamfile );
    my $header = $bam->header;
    my $a      = $bam->read1;
    my $tr     = $a->get_tag_values('tr');
    if   ( defined($tr) ) { return 1; }
    else                  { return 0; }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
