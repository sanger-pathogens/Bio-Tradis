package Bio::Tradis::CombinePlots;

# ABSTRACT: Combine multiple plotfiles and generate updated statistics for the combined files

=head1 SYNOPSIS

Takes a tab-delimited file with an ID as the first column followed by 
a list of plotfiles to combine per row. The ID will be used to name the new
plotfile and as an identifier in the stats file, so ensure these are unique.

For example, an input file named plots_to_combine.txt:

	tradis1	plot1.1.gz	plot1.2.gz plot1.3.gz
	tradis2 plot2.1.gz	plot2.2.gz
	tradis3	plot3.1.gz	plot3.2.gz plot3.3.gz	plot3.4.gz

will produce 
=over

=item 1. a directory named combined with 3 files - tradis1.insertion_site_plot.gz,
tradis2.insertion_site_plot.gz, tradis3.insertion_site_plot.gz
=item 2. a stats file named plots_to_combine.stats

=back

=head1 USAGE

   use Bio::Tradis::CombinePlots;
   
   my $pipeline = Bio::Tradis::CombinePlots->new(plotfile => 'abc');
   $pipeline->combine;

=cut

use Moose;
use strict;
use warnings;

has 'plotfile' => ( is => 'rw', isa => 'Str', required => 1 );
has '_plot_hash' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__plot_hash'
);
has '_stats_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__stats_handle'
);
has '_filehandle_hash' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__filehandle_hash'
);
has '_file_length_hash' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__file_length_hash'
);
has '_ordered_plot_ids' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__ordered_plot_ids'
);

sub _build__plot_hash {
    my ($self) = @_;
    my $plotfile = $self->plotfile;

    my %plot_hash;
    open( my $plots, $plotfile ) or die "Cannot find $plotfile";
    while ( my $line = <$plots> ) {
        my @fields     = split( /\s+/, $line );
        my $plot_id    = shift(@fields);
        my @full_paths = @{ $self->_abs_path_list( \@fields ) };
        $plot_hash{$plot_id} = [@full_paths];
    }
    close($plots);
    return \%plot_hash;
}

sub _build__stats_handle {
    my ($self) = @_;
    my $filelist = $self->plotfile;
    $filelist =~ s/([^\/]+$)//;
    my $filename = $1;
    $filename =~ s/[^\.]+$/stats/;
    open( my $stats, ">", $filename );
    return $stats;
}

sub _build__filehandle_hash {
    my ($self) = @_;
    my $plots = $self->_plot_hash;

    my %fh_hash;
    foreach my $key ( keys %{$plots} ) {

        #open a filehandle for each file to be combined
        my @filehandles;
        foreach my $p ( @{ ${$plots}{$key} } ) {
            open( my $p_fh, $p );
            push( @filehandles, $p_fh );
        }
        $fh_hash{$key} = [@filehandles];
    }
    return \%fh_hash;
}

sub _build__file_length_hash {
    my ($self) = @_;
    my $plots = $self->_plot_hash;

    my %lens_hash;
    foreach my $key ( keys %{$plots} ) {
        my ( $len, $wc );
        foreach my $p ( @{ ${$plots}{$key} } ) {
            $wc = `wc $p | awk '{print \$1}'`;
            chomp $wc;
            if ( defined $len && $wc != $len ) {
                die "Input files for ID $key are not of equal lengths\n";
            }
            elsif ( !defined $len ) {
                $len = $wc;
            }
        }
        $lens_hash{$key} = $len;
    }
    return \%lens_hash;
}

sub _build__ordered_plot_ids{
	my ($self) = @_;
    my $filelist = $self->plotfile;

	my @id_order = `awk '{print \$1}' $filelist`;
	foreach my $id (@id_order){
		chomp($id);
	}
	return \@id_order;
}

sub combine {
    my ($self) = @_;
    my $fhs    = $self->_filehandle_hash;
    my $lens   = $self->_file_length_hash;
	my $ordered_keys = $self->_ordered_plot_ids;
    $self->_write_stats_header;

    system("mkdir combined") unless ( -d "combined" );
    foreach my $key ( @{ $ordered_keys } ) {

        #create output plot file
        my $comb_plot_name = "combined/$key.insert_site_plot";
        my $comb_plot_cont = "";

        my $filelen = ${$lens}{$key};
        my ( @currentlines, $this_line );

        foreach my $i ( 0 .. $filelen ) {
            @currentlines = ();
            foreach my $curr_fh ( @{ ${$fhs}{$key} } ) {
                $this_line = <$curr_fh>;
                push( @currentlines, $this_line );
            }
            my $comb_line = $self->_combine_lines( \@currentlines );
            $comb_plot_cont .= "$comb_line\n";
        }
        open( CPLOT, '>', $comb_plot_name );
        print CPLOT $comb_plot_cont;
        close(CPLOT);

        $self->_write_stats($key);
        system("gzip $comb_plot_name");
    }
    return 1;
}

sub _combine_lines {
    my ( $self, $lines ) = @_;

    my @totals = ( 0, 0 );
    foreach my $l ( @{$lines} ) {
        my @cols = split( /\s+/, $l );
        $totals[0] += $cols[0];
        $totals[1] += $cols[1];
    }
    return join( " ", @totals );
}

sub _write_stats_header {
    my ($self) = @_;
    my @fields =
      ( "ID", "Sequence Length", "Unique Insertion Sites", "Seq Len/UIS" );
    print { $self->_stats_handle } join( ",", @fields ) . "\n";
    return 1;
}

sub _write_stats {
    my ( $self, $id ) = @_;
    my $comb_plot = "combined/$id.insert_site_plot";

    my $seq_len = `wc $comb_plot | awk '{print \$1}'`;
    chomp($seq_len);
    my $uis = `grep -c -v "0 0" $comb_plot`;
    chomp($uis);
    my $sl_per_uis = $seq_len / $uis;

    my $stats = "$id,$seq_len,$uis,$sl_per_uis\n";
    print { $self->_stats_handle } $stats;

    return 1;
}

sub _abs_path_list {
    my ( $self, $files ) = @_;
    my $plot_path = $self->_get_plotfile_path;

    my @pathlist;
    foreach my $f ( @{$files} ) {
        if   ( $f =~ /^\// ) { push( @pathlist, $f ); }
        else                 { push( @pathlist, $plot_path . $f ); }
    }
    return \@pathlist;
}

sub _get_plotfile_path {
    my ($self) = @_;
    my $plotfile = $self->plotfile;

    my @dirs = split( '/', $plotfile );
    pop(@dirs);
    my $path2plot = join( '/', @dirs );
    return "$path2plot/";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
