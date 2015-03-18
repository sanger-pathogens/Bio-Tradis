package Bio::Tradis::CombinePlots;

# ABSTRACT: Combine multiple plotfiles and generate updated statistics for the combined files

=head1 SYNOPSIS

Takes a tab-delimited file with an ID as the first column followed by 
a list of plotfiles to combine per row. The ID will be used to name the new
plotfile and as an identifier in the stats file, so ensure these are unique.

For example, an input file named plots_to_combine.txt:

    tradis1 plot1.1.gz  plot1.2.gz plot1.3.gz
    tradis2 plot2.1.gz  plot2.2.gz
    tradis3 plot3.1.gz  plot3.2.gz plot3.3.gz   plot3.4.gz

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
use File::Temp;
use File::Path qw( remove_tree );
use Data::Dumper;
use Cwd;
use Bio::Tradis::Analysis::Exceptions;

has 'plotfile'     => ( is => 'rw', isa => 'Str', required => 1 );
has 'combined_dir' => ( is => 'rw', isa => 'Str', default  => 'combined' );
has '_plot_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__plot_handle'
);
has '_stats_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__stats_handle'
);
has '_ordered_plot_ids' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__ordered_plot_ids'
);
has '_destination' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build__destination'
);

sub _build__destination {
    my $tmp_dir = File::Temp->newdir( DIR=> getcwd, CLEANUP => 0 );
    return $tmp_dir->dirname;
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

sub _build__plot_handle {
    my ($self) = @_;
    my $plot = $self->plotfile;
    open( my $plot_h, "<", $plot );
    return $plot_h;
}

sub _build__ordered_plot_ids {
    my ($self) = @_;
    my $filelist = $self->plotfile;

    my @id_order = `awk '{print \$1}' $filelist`;
    foreach my $id (@id_order) {
        chomp($id);
    }
    return \@id_order;
}

sub combine {
    my ($self)       = @_;
    my $ordered_keys = $self->_ordered_plot_ids;
    my $plot_handle  = $self->_plot_handle;
    my $combined_dir = $self->combined_dir;

    $self->_write_stats_header;


    system("mkdir $combined_dir") unless ( -d "$combined_dir" );
    my @tabix_plot;

    while ( my $line = <$plot_handle> ) {
        #parse line into hash. keys = id, len, files. unzips files if needed.
        my %plothash = $self->_parse_line($line);
        my $id       = $plothash{'id'};

        #create output plot file
        my $comb_plot_name = "$combined_dir/$id.insert_site_plot";
        my $filelen = $plothash{'len'};
        my ( @currentlines, $this_line );

        my @full_plot;
        foreach my $i ( 0 .. $filelen ) {
            @currentlines = ();

            foreach my $curr_fh ( @{ $plothash{'files'} } ) {
                $this_line = <$curr_fh>;
                push( @currentlines, $this_line ) if( defined $line && $line ne "");
            }

            my $comb_line = $self->_combine_lines( \@currentlines );

	    my $plot_values_tabix = $comb_line;
	    $plot_values_tabix =~ s/\s/\t/ if(defined $plot_values_tabix && $plot_values_tabix ne "");

	    my $tabix_line;
	    if ($id !~ m/^zip_combined/) {
	      my $tabix_line = "$id\t$i\t" . $plot_values_tabix if( defined $plot_values_tabix && $plot_values_tabix ne "");
	      push( @tabix_plot, $tabix_line ) if( $comb_line ne "");
	    }

            push(@full_plot, $comb_line) if ( $comb_line ne '' );
        }

        open( CPLOT, '>', $comb_plot_name );
        print CPLOT join("\n", @full_plot);
        close(CPLOT);

        $self->_write_stats($id, $filelen);
        system("gzip -f $comb_plot_name");
    }


    if (@tabix_plot) {
      $self->_prepare_and_create_tabix_for_combined_plots(\@tabix_plot);
    }

	File::Temp::cleanup();
    # double check tmp dir is deleted. cleanup not working properly
    remove_tree($self->_destination);
    return 1;
}

sub _prepare_and_create_tabix_for_combined_plots {

  my ($self, $tabix_plot) = @_;

  my $tabix_plot_name = "combined/tabix.insert_site_plot.gz";
  my $sorted_tabix_plot_name = "combined/tabix_sorted.insert_site_plot.gz";

  open(my $tabix_plot_fh , '|-', " gzip >". $tabix_plot_name) or warn "Couldn't create the initial plot file for tabix";
  print $tabix_plot_fh join( "\n", @{ $tabix_plot } );
  close($tabix_plot_fh);

  `cat $tabix_plot_name | gunzip - | sort -k1,1 -k2,2n | bgzip > $sorted_tabix_plot_name && tabix -b 2 -e 2 $sorted_tabix_plot_name`;
  unlink($tabix_plot_name);

}


sub _parse_line {
    my ( $self, $line ) = @_;
    chomp $line;
    my @fields = split( /\s+/, $line );
    my $id     = shift @fields;
    my @files = @{ $self->_unzip_plots(\@fields) };
    my $len    = $self->_get_file_len( \@files );
    if ( $len == 0 ){
        die "\nPlots with ID $id not of equal length.\n";
    }
    #build file handles for each file
    my @file_hs;
    foreach my $f (@files){
        open(my $fh, "<", $f);
        push(@file_hs, $fh);
    }
    return ( id => $id, len => $len, files => \@file_hs );
}

sub _get_file_len {
    my ( $self, $files ) = @_;

    #check all files are of equal lens and return len if true
    #wc misses last line - return $l++
    my @lens;
    for my $f ( @{$files} ) {
        my $wc = `wc $f | awk '{print \$1}'`;
        chomp $wc;
        push( @lens, $wc );
    }

    my $l = shift @lens;
    for my $x (@lens) {
        return 0 if ( $x != $l );
    }
    return $l+1;
}

sub _combine_lines {
    my ( $self, $lines ) = @_;

    my @totals = ( 0, 0 );
    foreach my $l ( @{$lines} ) {
        if(!defined($l)){
            return "";
            next;
        }
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
    my ( $self, $id, $seq_len ) = @_;
    my $combined_dir = $self->combined_dir;
    my $comb_plot = "$combined_dir/$id.insert_site_plot";

    #my $seq_len = `wc $comb_plot | awk '{print \$1}'`;
    #chomp($seq_len);
    my $uis = `grep -c -v "0 0" $comb_plot`;
    chomp($uis);
    my $sl_per_uis = "NaN";
    $sl_per_uis = $seq_len / $uis if($uis > 0);

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

sub _is_gz {
    my ( $self, $plotname ) = @_;

    if ( $plotname =~ /\.gz$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _unzip_plots {
    my ( $self, $files ) = @_;
    my $destination_directory = $self->_destination;

    my @filelist = @{ $self->_abs_path_list($files) };
    my @unz_plots;
    foreach my $plotname ( @filelist ) {
        Bio::Tradis::Analysis::Exceptions::FileNotFound->throw("Cannot find $plotname\n") unless ( -e $plotname );
        if ( $self->_is_gz($plotname) ) {
            $plotname =~ /([^\/]+$)/;
            my $unz = $1;
            $unz =~ s/\.gz//;
            my $unzip_cmd = "gunzip -c $plotname > $destination_directory/$unz";
            system($unzip_cmd);
            push(@unz_plots, "$destination_directory/$unz");
        }
        else {
            push(@unz_plots, $plotname);
        }
    }
    return \@unz_plots;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
