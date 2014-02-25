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
  ( is => 'rw', isa => 'Int', required => 0, default => 30 );
has 'smalt_k' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_s' => ( is => 'rw', isa => 'Maybe[Int]', required => 0 );
has 'smalt_y' => ( is => 'rw', isa => 'Maybe[Num]', required => 0 );

has '_stats_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__stats_handle'
);

sub BUILD {
    my ($self) = @_;

    my (
        $fastqfile, $tag,     $td,      $mismatch, $ref,
        $map_score, $smalt_k, $smalt_s, $smalt_y, $help
    );

    GetOptionsFromArray(
        $self->args,
        'f|fastqfile=s'     => \$fastqfile,
        't|tag=s'           => \$tag,
        'td|tagdirection=i' => \$td,
        'mm|mismatch=i'     => \$mismatch,
        'r|reference=s'     => \$ref,
        'm|mapping_score=i' => \$map_score,
        'sk|smalt_k=i'      => \$smalt_k,
        'ss|smalt_s=i'      => \$smalt_s,
        'sy|smalt_y=f'      => \$smalt_y,
        'h|help'            => \$help
    );

    $self->fastqfile( abs_path($fastqfile) ) if ( defined($fastqfile) );
    $self->tag( uc($tag) )                   if ( defined($tag) );
    $self->tagdirection($td)                 if ( defined($td) );
    $self->mismatch($mismatch)               if ( defined($mismatch) );
    $self->reference( abs_path($ref) )       if ( defined($ref) );
    $self->mapping_score($map_score)         if ( defined($map_score) );
    $self->smalt_k($smalt_k)                 if ( defined($smalt_k) );
    $self->smalt_s($smalt_s)                 if ( defined($smalt_s) );
    $self->smalt_y($smalt_y)                 if ( defined($smalt_y) );
    $self->help($help)                       if ( defined($help) );

    # print usage text if required parameters are not present
    ( $fastqfile && $tag && $ref ) or die $self->usage_text;
}

sub run {
    my ($self) = @_;

    if ( defined( $self->help ) ) {

        #if ( scalar( @{ $self->args } ) == 0 ) {
        $self->usage_text;
    }

    #parse list of files and run pipeline for each one if they all exist
    my $fq = $self->fastqfile;
    open( FILES, "<", $fq ) or die "Cannot find $fq";
    my @filelist = <FILES>;
    my $file_dir = $self->get_file_dir;

    #check files exist before running
    my $line_no = 0;
    my $full_path;
    foreach my $f1 (@filelist) {
        chomp($f1);
        $line_no++;
        if   ( $f1 =~ /^\// ) { $full_path = $f1; }
        else                  { $full_path = "$file_dir/$f1"; }
        unless ( -e $full_path ) {
            die "File $full_path does not exist ($fq, line $line_no)\n";
        }
    }

    #if all files exist, continue with analysis
    foreach my $f2 (@filelist) {
        chomp($f2);
        if   ( $f2 =~ /^\// ) { $full_path = $f2; }
        else                  { $full_path = "$file_dir/$f2"; }
        my $analysis = Bio::Tradis::RunTradis->new(
            fastqfile     => $full_path,
            tag           => $self->tag,
            tagdirection  => $self->tagdirection,
            mismatch      => $self->mismatch,
            reference     => $self->reference,
            mapping_score => $self->mapping_score,
            _stats_handle => $self->_stats_handle,
            smalt_k       => $self->smalt_k,
            smalt_s       => $self->smalt_s,
            smalt_y       => $self->smalt_y
        );
        $analysis->run_tradis;
    }
    $self->_tidy_stats;
    close(FILES);

    #$self->_combine_plots;
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
    open( STATS, '<', $filelist );
    open( TMP,   '>', 'tmp.stats' );

    my $header = 0;
    while ( my $line = <STATS> ) {
        if ( $line =~ /^File/ ) {
            if ( $header == 0 ) {
                print TMP "$line";
                $header = 1;
            }
        }
        else {
            print TMP "$line";
        }
    }
    close(TMP);
    close(STATS);
    system("mv tmp.stats $filelist");
}

sub _combine_plots {
    my ($self) = @_;
    my $filelist = $self->fastqfile;

    return 1;
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
-f        : list of fastq files with tradis tags attached
-t        : tag to search for
-r        : reference genome in fasta format (.fa)
-td       : tag direction - 3 or 5 (optional. default = 3)
-mm       : number of mismatches allowed when matching tag (optional. default = 0)
-m        : mapping quality cutoff score (optional. default = 30)
--smalt_k : custom k-mer value for SMALT mapping
--smalt_s : custom step size for SMALT mapping
--smalt_y : custom 
USAGE
    exit;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
