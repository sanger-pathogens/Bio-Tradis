package Bio::Tradis::CommandLine::CheckTags;

# ABSTRACT: Check for presence of tr tag in BAM file

=head1 SYNOPSIS

Check for presence of tr tag in BAM file

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::DetectTags;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'bamfile'        => ( is => 'rw', isa => 'Str', required => 0 );
has 'help'        => ( is => 'rw', isa => 'Bool', required => 0 );

sub BUILD {
    my ($self) = @_;
    
    my (
        $bamfile,	$help
    );

    GetOptionsFromArray(
        $self->args,
        'b|bamfile=s'                     => \$bamfile,
		'h|help'                           => \$help
    );
	
    $self->bamfile(abs_path($bamfile))                   if ( defined($bamfile) );
	$self->help($help)                                   if ( defined($help) );

}

sub run {
	my ($self) = @_;
	if(defined($self->help)){
		print "Help here";
	}
	
	my $tagcheck = Bio::Tradis::DetectTags->new(bamfile => $self->bamfile);
	$tagcheck->tags_present;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;