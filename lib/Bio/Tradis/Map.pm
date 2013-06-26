package Bio::Tradis::Map;

# ABSTRACT: Perform mapping

=head1 SYNOPSIS

Takes a reference genome and indexes it.
Maps given fastq files to ref.

   use Bio::Tradis::Map;
   
   my $pipeline = Bio::Tradis::Map->new(fastqfile => 'abc', reference => 'abc');
   $pipeline->index_ref();
   $pipeline->do_mapping();

=cut

use Moose;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'reference' => ( is => 'rw', isa => 'Str', required => 1 );
has 'refname'   => ( is => 'rw', isa => 'Str', required => 0 );
has 'outfile'   => ( is => 'rw', isa => 'Str', required => 0 );

sub index_ref {
    my ($self)  = @_;
    my $ref     = $self->reference;
    my $refname = $self->refname;

    system("smalt index -k 13 -s 4 $refname $ref");
    return 1;
}

sub do_mapping {
    my ($self)  = @_;
    my $fqfile  = $self->fastqfile;
    my $refname = $self->refname;
    my $outfile = $self->outfile;

    system("smalt map -x -r -1 -y 0.95 $refname $fqfile > $outfile");
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
