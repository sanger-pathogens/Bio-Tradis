package Bio::Tradis::DetectTags;

# ABSTRACT: Detect tr tags in BAM file


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

__END__

=pod

=head1 NAME

Bio::Tradis::DetectTags - Detect tr tags in BAM file

=head1 VERSION

version 1.132140

=head1 SYNOPSIS

Detects presence of tr/tq tags in BAM files from Tradis analyses
   use Bio::Tradis::DetectTags;

   my $pipeline = Bio::Tradis::DetectTags->new(bamfile => 'abc');
   $pipeline->tags_present();

=head1 AUTHOR

Carla Cummins <cc21@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
