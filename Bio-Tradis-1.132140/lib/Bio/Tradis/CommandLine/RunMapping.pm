package Bio::Tradis::CommandLine::RunMapping;

# ABSTRACT: Perform mapping


use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::Map;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'reference'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool',     required => 0 );
has 'refname' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'ref.index' );
has 'outfile' =>
  ( is => 'rw', isa => 'Str', required => 0, default => 'mapped.sam' );

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $ref, $refname, $outfile, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s' => \$fastqfile,
        'r|reference=s' => \$ref,
        'rn|refname=s'  => \$refname,
        'o|outfile=s'   => \$outfile,
        'h|help'        => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->reference( abs_path($ref) )       if ( defined($ref) );
    $self->refname($refname)                 if ( defined($refname) );
    $self->outfile( abs_path($outfile) )     if ( defined($outfile) );
    $self->help($help)                       if ( defined($help) );

	# print usage text if required parameters are not present
	($fastqfile && $ref) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {
    #if ( scalar( @{ $self->args } ) == 0 ) {
          $self->usage_text;
    }

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => $self->fastqfile,
        reference => $self->reference,
        refname   => $self->refname,
        outfile   => $self->outfile
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

sub usage_text {
      print <<USAGE;
Indexes the reference genome and maps the given fastq file.
-k and -s options for indexing are calculated for the length of
the read as follows
Read length    | k  |  s
---------------+----+-----
<70            | 13 |  4
>70 & <100     | 13 |  6
>100           | 20 |  13

Usage: run_mapping -f file.fastq -r ref.fa [options]

Options:
-f  : fastq file to map
-r	: reference in fasta format
-rn : reference index name (optional. default: ref.index)
-o  : mapped SAM output name (optional. default: mapped.sam)

USAGE
      exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::Tradis::CommandLine::RunMapping - Perform mapping

=head1 VERSION

version 1.132140

=head1 SYNOPSIS

Takes a reference genome and indexes it.
Maps given fastq files to ref.

=head1 AUTHOR

Carla Cummins <cc21@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
