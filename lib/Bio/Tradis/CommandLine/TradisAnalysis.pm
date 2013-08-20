package Bio::Tradis::CommandLine::TradisAnalysis;

# ABSTRACT: Perform full tradis analysis

=head1 SYNOPSIS

Takes a fastq, reference and a tag and generates insertion
site plots for use in Artemis

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd 'abs_path';
use Bio::Tradis::RunTradis;

has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'fastqfile'   => ( is => 'rw', isa => 'Str',      required => 0 );
has 'tag'         => ( is => 'rw', isa => 'Str',      required => 0 );
has 'mismatch' => ( is => 'rw', isa => 'Int', required => 0, default => 0 );
has 'tagdirection' =>
  ( is => 'rw', isa => 'Str', required => 0, default => '3' );
has 'reference' => ( is => 'rw', isa => 'Str',  required => 0 );
has 'help'      => ( is => 'rw', isa => 'Bool', required => 0 );
has 'mapping_score' =>
  ( is => 'ro', isa => 'Int', required => 0, default => 30 );
has '_stats_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__stats_handle'
);

sub BUILD {
    my ($self) = @_;

    my ( $fastqfile, $tag, $td, $mismatch, $ref, $map_score, $help );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s'     => \$fastqfile,
        't|tag=s'           => \$tag,
        'td|tagdirection=i' => \$td,
        'mm|mismatch=i'     => \$mismatch,
        'r|reference=s'     => \$ref,
        'm|mapping_score=i' => \$map_score,
        'h|help'            => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->tag( uc($tag) )                   if ( defined($tag) );
    $self->tagdirection($td)                 if ( defined($td) );
    $self->mismatch($mismatch)               if ( defined($mismatch) );
    $self->reference( abs_path($ref) )       if ( defined($ref) );
    $self->mapping_score($map_score)         if ( defined($map_score) );
    $self->help($help)                       if ( defined($help) );

	# print usage text if required parameters are not present
	($fastqfile && $tag && $ref) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {

        #if ( scalar( @{ $self->args } ) == 0 ) {
        $self->usage_text;
    }

    #parse list of files and run pipeline for each one if they all exist
	my $fq = $self->fastqfile;
    open( FILES, "<", $fq );
    my @filelist = <FILES>;
	my $file_dir = "";
	unless($fq =~ /^\//){$file_dir = $self->get_file_dir;}
	#check files exist before running
	my $line_no = 0;
	foreach my $f1 (@filelist){
		chomp($f1);
		$line_no++;
		unless (-e "$file_dir/$f1"){
			die "File $file_dir/$f1 does not exist ($fq, line $line_no)\n";
		}
	}
	
	#if all files exist, continue with analysis
    foreach my $f2 (@filelist) {
        chomp($f2);
		if( substr($f2, 0, 1) ne "/"){
			$f2 = "$file_dir/$f2";
		}
        my $analysis = Bio::Tradis::RunTradis->new(
            fastqfile      => $f2,
            tag            => $self->tag,
            tagdirection   => $self->tagdirection,
            mismatch       => $self->mismatch,
            reference      => $self->reference,
            mapping_score  => $self->mapping_score,
            _stats_handle  => $self->_stats_handle
        );
        $analysis->run_tradis;
    }
	$self->_tidy_stats;
    close(FILES);
}

sub _build__stats_handle {
    my ($self)   = @_;
    my $filelist = $self->fastqfile;
    my $dir      = $self->get_file_dir;
    $filelist =~ s/$dir\///;
    $filelist =~ s/[^\.]+$/stats/;
    open( my $stats, ">", "$filelist" );
    return $stats;
}

sub _tidy_stats {
	my ($self)   = @_;
    my $filelist = $self->fastqfile;
    my $dir      = $self->get_file_dir;
    $filelist =~ s/$dir\///;
    $filelist =~ s/[^\.]+$/stats/;
	open(STATS, '<', $filelist);
	open(TMP, '>', 'tmp.stats');

	my $header = 0;
	while(my $line = <STATS>){
		if($line =~ /^File/){
			if($header == 0){
				print TMP "$line";
				$header = 1;
			}
		}
		else{
			print TMP "$line";
		}
	}
	close(TMP);
	close(STATS);
	system("mv tmp.stats $filelist");
}

sub get_file_dir {
    my ($self) = @_;
    my $fq = $self->fastqfile;

    my @dirs = split( '/', $fq );
    pop(@dirs);
    return join( '/', @dirs );
}

sub usage_text {
    print <<USAGE;
Run a TraDIS analysis. This involves:
1: filtering the data with tags matching that passed via -t option
2: removing the tags from the sequences
3: mapping
4: creating an insertion site plot
5: creating a stats summary

Usage: bacteria_tradis [options]

Options:
-f  : list of fastq files with tradis tags attached
-t  : tag to search for
-r  : reference genome in fasta format (.fa)
-td : tag direction - 3 or 5 (optional. default = 3)
-mm : number of mismatches allowed when matching tag (optional. default = 0)
-m  : mapping quality cutoff score (optional. default = 30)

USAGE
    exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
