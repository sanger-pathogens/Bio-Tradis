package Bio::Tradis::RunTradis;

# ABSTRACT: Perform all steps required for a tradis analysis

=head1 SYNOPSIS

Takes a fastq file with tags already attached, filters the tags matching user input,
removes the tags, maps to a reference (.fa) and generates insertion site plots for use in
Artemis (or other genome browsers), mapped BAM files for each lane and a statistical summary of the analysis.

   use Bio::Tradis::RunTradis;
   
   my $pipeline = Bio::Tradis::RunTradis->new(
					fastqfile => 'abc',  
					reference => 'abc',
					tag => 'abc',
					tagdirection => '5'|'3'
   );
   $pipeline->run_tradis();

=head1 PARAMETERS

=head2 Required

=over

=item * C<fastqfile> - file containing a list of fastqs (gzipped or raw) to run the 
			complete analysis on. This includes all (including 
			intermediary format conversion and sorting) steps starting from
			filtering.

=item * C<tag> - TraDIS tag to filter and then remove

=item * C<reference> - path to/name of reference genome in fasta format (.fa)

=back

=head2 Optional

=over

=item * C<mismatch> - number of mismatches to allow when filtering/removing the tag. Default = 0

=item * C<tagdirection> - direction of the tag, 5' or 3'. Default = 3

=item * C<mapping_score> - cutoff value for mapping score when creating insertion site plots. Default = 30

=back

=head1 METHODS

C<run_tradis> - run complete analysis with given parameters

=cut

use Cwd;
use Moose;
use File::Temp;
use File::Path 'rmtree';
use Bio::Tradis::FilterTags;
use Bio::Tradis::RemoveTags;
use Bio::Tradis::Map;
use Bio::Tradis::TradisPlot;
use Bio::Tradis::Exception;
use Bio::Tradis::Samtools;

has 'verbose' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'fastqfile' => ( is => 'rw', isa => 'Str', required => 1 );
has '_unzipped_fastq' =>
  ( is => 'rw', isa => 'Str', lazy => 1, builder => '_build__unzipped_fastq' );
has 'tag' => ( is => 'ro', isa => 'Str', required => 1 );
has 'tagdirection' =>
  ( is => 'ro', isa => 'Str', required => 1, default => '3' );
has 'mismatch' => ( is => 'rw', isa => 'Int', required => 1, default => 0 );
has 'mapping_score' =>
  ( is => 'ro', isa => 'Int', required => 1, default => 30 );
has 'reference' => ( is => 'rw', isa => 'Str', required => 1 );
has 'outfile' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    default  => sub {
        my ($self) = @_;
        my @dirs = split( '/', $self->fastqfile );
        my $o = pop(@dirs);
        $o =~ s/fastq/out/;
        return $o;
    }
);
has 'smalt_k' => ( is => 'rw', isa => 'Maybe[Int]',   required => 0 );
has 'smalt_s' => ( is => 'rw', isa => 'Maybe[Int]',   required => 0 );
has 'smalt_y' => ( is => 'rw', isa => 'Maybe[Num]', required => 0, default => 0.96 );
has 'smalt_r' => ( is => 'rw', isa => 'Maybe[Int]', required => 0, default => -1);
has 'smalt_n' => ( is => 'rw', isa => 'Maybe[Int]', required => 0, default => 1);
has 'samtools_exec' => ( is => 'rw', isa => 'Str', default => 'samtools' );

has '_temp_directory' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build__temp_directory'
);
has 'output_directory' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build_output_directory'
);
has '_stats_handle' => ( is => 'ro', isa => 'FileHandle', required => 1 );
has '_sequence_info' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    lazy     => 1,
    builder  => '_build__sequence_info'
);
has '_current_directory' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build__current_directory'
);

sub _is_gz {
    my ($self) = @_;
    my $fq = $self->fastqfile;

    if ( $fq =~ /\.gz/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _build__unzipped_fastq {
    my ($self)                = @_;
    my $fq                    = $self->fastqfile;
    my $temporary_directory   = $self->_temp_directory;

    if ( $self->_is_gz ) {
        $fq =~ /([^\/]+)$/;
        my $newfq = $1;
        $newfq =~ s/\.gz//;
        if ( !-e "$temporary_directory/$newfq" ) {
            `gunzip -c $fq > $temporary_directory/$newfq`;
        }
        return "$temporary_directory/$newfq";
    }
    else {
        return $fq;
    }
}

sub _build__stats_handle {
    my ($self) = @_;
    my $outfile = $self->outfile;

    open( my $stats, ">", "$outfile.stats" );
    return $stats;
}

sub _build__sequence_info {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;
    open( GREP,
        "grep \@SQ $temporary_directory/mapped.sam | awk '{print \$2, \$3}' |"
    );
    my %sns = ();
    while ( my $sn = <GREP> ) {
        chomp($sn);
        $sn =~ /SN:(\S+)\s+LN:(\d+)/;
        $sns{$1} = $2;
    }
    return \%sns;
}

sub _build__temp_directory {
    my ($self) = @_;
    my $tmp_dir = File::Temp->newdir( 'tmp_run_tradis_XXXXX',
                                      CLEANUP => 0,
                                      DIR => $self->output_directory );
    return $tmp_dir->dirname;
}

sub _build_output_directory {
    return cwd();
}

sub _build__current_directory {
    my ($self) = @_;
    my $fq = $self->fastqfile;

    my @dirs = split( '/', $fq );
    pop(@dirs);
    return join( '/', @dirs );
}

sub run_tradis {
    my ($self)                = @_;
    my $temporary_directory   = $self->_temp_directory;
    my $fq                    = $self->fastqfile;
    
    my $ref                   = $self->reference;
    Bio::Tradis::Exception::RefNotFound->throw( error => "$ref not found\n" ) unless( -e $ref );

    print STDERR "::::::::::::::::::\n$fq\n::::::::::::::::::\n\n" if($self->verbose);

    # Step 1: Filter tags that match user input tag
    print STDERR "..........Step 1: Filter tags that match user input tag\n" if($self->verbose);
    $self->_filter;

    print STDERR "..........Step 1.1: Check that at least one read started with the tag\n" if($self->verbose);
    $self->_check_filter;

    # Step 2: Remove the tag from the sequence and quality strings
    print STDERR
"..........Step 2: Remove the tag from the sequence and quality strings\n" if($self->verbose);
    $self->_remove;

    # Step 3: Map file to reference
    print STDERR "..........Step 3: Map file to reference\n" if($self->verbose);
    $self->_map;

    # Step 4: Convert output from SAM to BAM, sort and index
    print STDERR
      "..........Step 3.5: Convert output from SAM to BAM and sort\n" if($self->verbose);
    $self->_sam2bam;
    $self->_sort_bam;
    $self->_bamcheck;

    # Step 5: Generate plot
    print STDERR "..........Step 4: Generate plot\n" if($self->verbose);
    $self->_make_plot;

    # Step 6: Generate statistics
    print STDERR "..........Step 5: Generate statistics\n" if($self->verbose);
    $self->_stats;

    # Step 7: Move files to current directory
    print STDERR "..........Step 6: Move files to current directory\n" if($self->verbose);
    my $outfile = $self->outfile;
    my $output_directory = $self->output_directory;
    system("mv $temporary_directory/$outfile* $output_directory");
    system("mv $temporary_directory/mapped.sort.bam $output_directory/$outfile.mapped.bam");
    system("mv $temporary_directory/mapped.sort.bam.bai $output_directory/$outfile.mapped.bam.bai");
    system("mv $temporary_directory/mapped.bamcheck $output_directory/$outfile.mapped.bamcheck");

    # Clean up
    print STDERR "..........Clean up\n" if($self->verbose);

    rmtree($temporary_directory);

    return 1;
}

sub _filter {
    my ($self)                = @_;
    my $temporary_directory   = $self->_temp_directory;
    my $fqfile                = $self->_unzipped_fastq;
    my $tag                   = $self->tag;
    my $mm                    = $self->mismatch;

    my $filter = Bio::Tradis::FilterTags->new(
        fastqfile => $fqfile,
        tag       => $tag,
        mismatch  => $mm,
        outfile   => "$temporary_directory/filter.fastq"
    )->filter_tags;
}

sub _check_filter {
    my ($self)                 = @_;
    my $temporary_directory    = $self->_temp_directory;
    my $filtered_file_filename = "$temporary_directory/filter.fastq";
    open my $filtered_file, '<', $filtered_file_filename or
       Bio::Tradis::Exception::TagFilterError->throw( error => "There was a problem filtering reads by the specified tag.  Please check all input files are Fastq formatted and that at least one read in each starts with the specified tag\n" );
    my @first_read_data;
    while( my $line = <$filtered_file> ) {
      last if $. > 4;
      chomp($line);
      push @first_read_data, $line;
    }
    my $number_of_read_lines = scalar @first_read_data;
    if ( $number_of_read_lines ne 4) {
      # There wasn't enough data for a complete read
      Bio::Tradis::Exception::TagFilterError->throw( error => "There was a problem filtering reads by the specified tag.  Please check all input files are Fastq formatted and that at least one read in each starts with the specified tag\n" );
    }
    my $read_plus_sign = $first_read_data[2];
    if ( $read_plus_sign ne '+' ) {
      # The first 'read' didn't have a '+' on the third line, suspicious
      Bio::Tradis::Exception::TagFilterError->throw( error => "There was a problem filtering reads by the specified tag.  Please check all input files are Fastq formatted and that at least one read in each starts with the specified tag\n" );
    }
    # I'm not proposing further (more detailed) validation here
    close $filtered_file;
}

sub _remove {
    my ($self)                = @_;
    my $temporary_directory   = $self->_temp_directory;
    my $tag                   = $self->tag;
    my $mm                    = $self->mismatch;

    my $rm_tags = Bio::Tradis::RemoveTags->new(
        fastqfile => "$temporary_directory/filter.fastq",
        tag       => $tag,
        mismatch  => $mm,
        outfile   => "$temporary_directory/tags_removed.fastq"
    )->remove_tags;
}

sub _map {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;

    my $ref = $self->reference;

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => "$temporary_directory/tags_removed.fastq",
        reference => "$ref",
        refname   => "$temporary_directory/ref.index",
        outfile   => "$temporary_directory/mapped.sam",
        smalt_k   => $self->smalt_k,
        smalt_s   => $self->smalt_s,
        smalt_y   => $self->smalt_y,
        smalt_r   => $self->smalt_r,
        smalt_n   => $self->smalt_n
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

sub _sam2bam {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;

    system(
$self->samtools_exec." view -b -o $temporary_directory/mapped.bam -S $temporary_directory/mapped.sam"
    );
    return 1;
}

sub _sort_bam {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;

		my $samtools_obj = Bio::Tradis::Samtools->new(exec => $self->samtools_exec, threads => $self->smalt_n);
    $samtools_obj->run_sort("$temporary_directory/mapped.bam","$temporary_directory/mapped.sort");
    $samtools_obj->run_index("$temporary_directory/mapped.sort.bam");
    return 1;
}

sub _bamcheck {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;

    system(
$self->samtools_exec." stats $temporary_directory/mapped.sort.bam > $temporary_directory/mapped.bamcheck"
    );
    return 1;
}

sub _make_plot {
    my ($self)                = @_;
    my $temporary_directory   = $self->_temp_directory;
    my $ref                   = $self->reference;
    my $outfile               = $self->outfile;
    my $tr_d                  = $self->tagdirection;

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile    => "$temporary_directory/mapped.sort.bam",
        mapping_score => $self->mapping_score,
        outfile       => "$temporary_directory/$outfile"
    )->plot;

    # if tag direction is 5, reverse plot columns
    if ( $self->tagdirection eq '5' ) {
        print STDERR "Tag direction = 5. Reversing plot..\n" if($self->verbose);
        $self->_reverse_plots;
    }
    return 1;
}

sub _reverse_plots {
    my ($self)                = @_;
    my $temporary_directory   = $self->_temp_directory;
    my $outfile               = $self->outfile;
    my @seqnames              = keys %{ $self->_sequence_info };

    my @current_plots =
      glob("$temporary_directory/$outfile.*.insert_site_plot.gz");

    foreach my $plotname (@current_plots) {
        print STDERR "Reversing $plotname\n" if($self->verbose);

        #my $plotname = $self->_plotname($sn);
        system("gunzip -c $plotname > $temporary_directory/tmp.plot");
        system(
"awk '{ t = \$1; \$1 = \$2; \$2 = t; print; }' $temporary_directory/tmp.plot > rv_plot"
        );
        system("gzip -c rv_plot > $plotname");
    }
    unlink("$temporary_directory/tmp.plot");
    unlink("rv_plot");
}

sub _stats {
    my ($self)                = @_;
    my $outfile               = $self->outfile;
    my $temporary_directory   = $self->_temp_directory;
    my $fq                    = $self->_unzipped_fastq;
    my $seq_info              = $self->_sequence_info;

    #write header to stats file
    $self->_write_stats_header;

    # Add file name and number of reads in it
    my @fql         = split( "/", $fq );
    my $stats       = "$fql[-1],";
    my $total_reads = `wc $fq | awk '{print \$1/4}'`;
    chomp($total_reads);
    $stats .= "$total_reads,";

    # Matching reads
    my $matching =
      `wc $temporary_directory/filter.fastq | awk '{print \$1/4}'`;
    chomp($matching);
    $stats .= "$matching,";
    $stats .= ( $matching / $total_reads ) * 100 . ",";

    # Mapped reads
    my $mapped = $self->_number_of_mapped_reads;
    $stats .= "$mapped,";
    $stats .= ( $mapped / $matching ) * 100 . ",";

    # Unique insertion sites
    my ( $total_uis, $total_seq_len );
    foreach my $si ( keys %{$seq_info} ) {
        my $plotname = $self->_plotname($si);
        system(
"gunzip -c $temporary_directory/$plotname > $temporary_directory/tmp.plot"
        );
        my $uis = `grep -c -v "0 0" $temporary_directory/tmp.plot`;
        chomp($uis);
        $total_uis += $uis;
        $stats .= "$uis,";
        my $seqlen = ${$seq_info}{$si};
        $total_seq_len += $seqlen;
        my $uis_per_seqlen = "NaN";
        $uis_per_seqlen = $seqlen / $uis if ( $uis > 0 );
        chomp($uis_per_seqlen);
        $stats .= "$uis_per_seqlen,";
    }
    $stats .= "$total_uis,";
    my $t_uis_p_l = "NaN";
    $t_uis_p_l = $total_seq_len / $total_uis if ( $total_uis > 0 );
    $stats .= "$t_uis_p_l\n";
    print { $self->_stats_handle } $stats;
}

sub _write_stats_header {
    my ($self)   = @_;
    my @seqnames = keys %{ $self->_sequence_info };
    my @fields   = (
        "File",
        "Total Reads",
        "Reads Matched",
        "\% Matched",
        "Reads Mapped",
        "\% Mapped"
    );
    print { $self->_stats_handle } join( ",", @fields ) . ",";
    foreach my $sn (@seqnames) {
        print { $self->_stats_handle } "Unique Insertion Sites : $sn,";
        print { $self->_stats_handle } "Seq Len/UIS : $sn,";
    }
    print { $self->_stats_handle } "Total Unique Insertion Sites,";
    print { $self->_stats_handle } "Total Seq Len/Total UIS\n";
}

sub _plotname {
    my ( $self, $seq_name ) = @_;
    my $outfile = $self->outfile;

    $seq_name =~ s/[^\w\d\.]/_/g;
    my $plotfile_name = "$outfile.$seq_name.insert_site_plot.gz";
    return $plotfile_name;
}

sub _number_of_mapped_reads {
    my ($self) = @_;
    my $temporary_directory = $self->_temp_directory;

    my $pars =
      Bio::Tradis::Parser::Bam->new(
        file => "$temporary_directory/mapped.bam" );
    my $c = 0;
    while ( $pars->next_read ) {
        if ( $pars->is_mapped ) {
            $c++;
        }
    }
    return $c;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
