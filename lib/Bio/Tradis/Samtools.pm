package Bio::Tradis::Samtools;

# ABSTRACT: Change samtools syntax depending on version found

=head1 SYNOPSIS

Change samtools syntax depending on version found
   use Bio::Tradis::Samtools;
   
   my $obj = Bio::Tradis::Samtools->new(
      exec => 'samtools'
     );

   $obj->run_sort();

=cut

use Moose;
use File::Spec;

has 'exec'         => ( is => 'ro', isa => 'Str', default => 'samtools' );
has 'threads'      => ( is => 'ro', isa => 'Int', default => 1 );
has 'exec_version' => ( is => 'ro', isa => 'Str', lazy    => 1, builder => '_build_exec_version' );

sub _build_exec_version {
    my ($self) = @_;
		
    my $fp = $self->find_exe($self->exec);
		if(!$fp)
		{
			 exit("ERROR: Can't find required ".$self->exec." in your \$PATH");
  	}
		my $cmd_version = $self->exec." 2>&1 | grep Version";
		my ($version_string) = qx($cmd_version);
		
		if(defined($version_string))
		{
			#Version: 0.1.19-44428cd
			#Version: 1.2 (using htslib 1.2)
			# we dont use 3rd number in version so just look for 0.1, 1.2
			if($version_string =~ /Version:[\t\s]+(\d+)\.(\d+)/)
			{
				return $1.'.'.$2;
			}
			else
			{
				print STDERR "ERROR: Couldn't identify samtools version";
			}
		}
		else
		{
			print STDERR "ERROR: Couldn't identify samtools version";
		}
		# reasonable fallback
    return '0.1';
}

sub find_exe {
    my ( $self, $bin ) = @_;
    for my $dir ( File::Spec->path ) {
        my $exe = File::Spec->catfile( $dir, $bin );
        return $exe if -x $exe;
    }
    return;
}

sub _is_version_less_than_1 {
    my ($self) = @_;
    if($self->exec_version < 1.0)
		{
			return 1;
		}
		else
		{
			return 0;
		}
}

sub run_sort {
    my ( $self, $input_file, $output_file ) = @_;

    my $cmd;
    if ( $self->_is_version_less_than_1 ) {
			  $output_file =~ s/\.bam//i;
        $cmd = join( ' ', ( $self->exec, 'sort',$output_file, $input_file) );
    }
    else {
        $cmd = join( ' ', ( $self->exec, 'sort', '-@', $self->threads, '-O', 'bam', '-T', $input_file.'.tmp',  '-o', $output_file, $input_file ) );
    }
    system($cmd);
}

sub run_index {
    my ( $self, $input_file ) = @_;
    system( $self->exec . " index $input_file" );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

