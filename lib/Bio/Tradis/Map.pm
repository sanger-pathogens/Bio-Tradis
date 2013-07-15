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
use Bio::Tradis::Parser::Fastq;

has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has 'reference' => ( is => 'rw', isa => 'Str', required => 1 );
has 'refname'   => ( is => 'rw', isa => 'Str', required => 0 );
has 'outfile'   => ( is => 'rw', isa => 'Str', required => 0 );

sub index_ref {
    my ($self)  = @_;
    my $ref     = $self->reference;
    my $refname = $self->refname;

    # Calculate index parameters
    my $pars = Bio::Tradis::Parser::Fastq->new( file => $self->fastqfile );
    $pars->next_read;
    my @read = $pars->read_info;
    my ( $k, $s );
    ( $k, $s ) = ( 13, 4 );
    my $seq = $read[1];
    if ( length($seq) < 70 ) {
        ( $k, $s ) = ( 13, 4 );
    }
    elsif ( length($seq) > 70 && length($seq) < 100 ) {
        ( $k, $s ) = ( 13, 6 );
    }
    else {
        ( $k, $s ) = ( 20, 13 );
    }

    system("smalt index -k $k -s $s $refname $ref");
    return 1;
}

sub do_mapping {
    my ($self)  = @_;
    my $fqfile  = $self->fastqfile;
    my $refname = $self->refname;
    my $outfile = $self->outfile;

    system("smalt map -x -r -1 -y 0.96 $refname $fqfile 1> $outfile  2> smalt.stderr");
	#my $smalt_exit = `tail -1 smalt.stderr`;
	#if($smalt_exit =~ m/wrong FASTQ\/FASTA format/){
	#	print STDERR "Problem with file format when mapping. Please check the file.\n";
	#	unlink('smalt.stderr');
	#	return 0;
	#}
	#else{
	#	print STDERR `cat smalt.stderr`;
	#	unlink('smalt.stderr');
	#	return 1;
	#}
	
	unlink('smalt.stderr');
	return 1;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
