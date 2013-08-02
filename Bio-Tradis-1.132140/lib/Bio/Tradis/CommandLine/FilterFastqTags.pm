package Bio::Tradis::CommandLine::FilterFastqTags;

# ABSTRACT: Remove given tags from the start of the sequence


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::FilterTags;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'tag'         => ( is => 'rw', isa => 'Str',      required => 0 );
has 'mismatch'    => ( is => 'rw', isa => 'Int',      required => 0, default => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'outfile'     => ( is => 'rw', isa => 'Str',      required => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $tag, $mismatch, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s' => \$fastqfile,
        't|tag=s'       => \$tag,
        'm|mismatch=i'  => \$mismatch,
        'o|outfile=s'   => \$outfile,
        'h|help'        => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->tag($tag)                         if ( defined($tag) );
    $self->mismatch($mismatch)               if ( defined($mismatch) );
    $self->outfile( abs_path($outfile) )     if ( defined($outfile) );
    $self->help($help)                       if ( defined($help) );

	# print usage text if required parameters are not present
	($fastqfile && $tag) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {

        #if ( scalar( @{ $self->args } ) == 0 ) {
        $self->usage_text;
    }

    my $tag_filter = Bio::Tradis::FilterTags->new(
        fastqfile => $self->fastqfile,
        tag       => $self->tag,
        mismatch  => $self->mismatch,
        outfile   => $self->outfile
    );
    $tag_filter->filter_tags;
}

sub usage_text {
    print <<USAGE;
Filters a BAM file and outputs reads with tag matching -t option

Usage: filter_tags -b file.bam -t tag [options]

Options:
-f  : fastq file with tradis tags attached
-t  : tag to search for
-m  : number of mismatches to allow when matching tag (optional. default = 0)
-o  : output file name (optional. default: <file>.tag.fastq)

USAGE
    exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::Tradis::CommandLine::FilterFastqTags - Remove given tags from the start of the sequence

=head1 VERSION

version 1.132140

=head1 SYNOPSIS

Removes tags from the sequence and quality strings

=head1 AUTHOR

Carla Cummins <cc21@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
