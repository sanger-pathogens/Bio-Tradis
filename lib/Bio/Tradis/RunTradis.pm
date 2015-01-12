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

use Moose;
use File::Temp;
use Bio::Tradis::FilterTags;
use Bio::Tradis::RemoveTags;
use Bio::Tradis::Map;
use Bio::Tradis::TradisPlot;
use Bio::Tradis::Exception;

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
has 'samtools_exec' => ( is => 'rw', isa => 'Str', default => 'samtools' );

has '_destination' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    lazy     => 1,
    builder  => '_build__destination'
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
    my $destination_directory = $self->_destination;

    if ( $self->_is_gz ) {
        $fq =~ /([^\/]+)$/;
        my $newfq = $1;
        $newfq =~ s/\.gz//;
        if ( !-e "$destination_directory/$newfq" ) {
            `gunzip -c $fq > $destination_directory/$newfq`;
        }
        return "$destination_directory/$newfq";
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
    my $destination_directory = $self->_destination;
    open( GREP,
        "grep \@SQ $destination_directory/mapped.sam | awk '{print \$2, \$3}' |"
    );
    my %sns = ();
    while ( my $sn = <GREP> ) {
        chomp($sn);
        $sn =~ /SN:(\S+)\s+LN:(\d+)/;
        $sns{$1} = $2;
    }
    return \%sns;
}

sub _build__destination {
    my $tmp_dir = File::Temp->newdir( CLEANUP => 0 );
    return $tmp_dir->dirname;
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
    my $destination_directory = $self->_destination;
    my $fq                    = $self->fastqfile;
    
    my $ref                   = $self->reference;
    Bio::Tradis::Exception::RefNotFound->throw( error => "$ref not found\n" ) unless( -e $ref );

    print STDERR "::::::::::::::::::\n$fq\n::::::::::::::::::\n\n";

    # Step 1: Filter tags that match user input tag
    print STDERR "..........Step 1: Filter tags that match user input tag\n";
    $self->_filter;

    # Step 2: Remove the tag from the sequence and quality strings
    print STDERR
"..........Step 2: Remove the tag from the sequence and quality strings\n";
    $self->_remove;

    # Step 3: Map file to reference
    print STDERR "..........Step 3: Map file to reference\n";
    $self->_map;

    # Step 4: Convert output from SAM to BAM, sort and index
    print STDERR
      "..........Step 3.5: Convert output from SAM to BAM and sort\n";
    $self->_sam2bam;
    $self->_sort_bam;
    $self->_bamcheck;

    # Step 5: Generate plot
    print STDERR "..........Step 4: Generate plot\n";
    $self->_make_plot;

    # Step 6: Generate statistics
    print STDERR "..........Step 5: Generate statistics\n";
    $self->_stats;

    # Step 7: Move files to current directory
    print STDERR "..........Step 6: Move files to current directory\n";
    my $outfile = $self->outfile;
    system("mv $destination_directory/$outfile* \.");
    system("mv $destination_directory/mapped.sort.bam \./$outfile.mapped.bam");
    system("mv $destination_directory/mapped.sort.bam.bai \./$outfile.mapped.bam.bai");
    system("mv $destination_directory/mapped.bamcheck \./$outfile.mapped.bamcheck");

    # Clean up
    print STDERR "..........Clean up\n";

    unlink("$destination_directory/filter.fastq");
    unlink("$destination_directory/tags_removed.fastq");
    unlink("$destination_directory/mapped.sam");
    unlink("$destination_directory/ref.index.sma");
    unlink("$destination_directory/ref.index.smi");
    unlink("$destination_directory/mapped.bam");
    unlink("$destination_directory/tmp.plot");
    unlink( $self->_unzipped_fastq ) if ( $self->_is_gz );

    File::Temp::cleanup();

    return 1;
}

sub _filter {
    my ($self)                = @_;
    my $destination_directory = $self->_destination;
    my $fqfile                = $self->_unzipped_fastq;
    my $tag                   = $self->tag;
    my $mm                    = $self->mismatch;

    my $filter = Bio::Tradis::FilterTags->new(
        fastqfile => $fqfile,
        tag       => $tag,
        mismatch  => $mm,
        outfile   => "$destination_directory/filter.fastq"
    )->filter_tags;
}

sub _remove {
    my ($self)                = @_;
    my $destination_directory = $self->_destination;
    my $tag                   = $self->tag;
    my $mm                    = $self->mismatch;

    my $rm_tags = Bio::Tradis::RemoveTags->new(
        fastqfile => "$destination_directory/filter.fastq",
        tag       => $tag,
        mismatch  => $mm,
        outfile   => "$destination_directory/tags_removed.fastq"
    )->remove_tags;
}

sub _map {
    my ($self) = @_;
    my $destination_directory = $self->_destination;

    my $ref = $self->reference;

    my $mapping = Bio::Tradis::Map->new(
        fastqfile => "$destination_directory/tags_removed.fastq",
        reference => "$ref",
        refname   => "$destination_directory/ref.index",
        outfile   => "$destination_directory/mapped.sam",
        smalt_k   => $self->smalt_k,
        smalt_s   => $self->smalt_s,
        smalt_y   => $self->smalt_y
    );
    $mapping->index_ref;
    $mapping->do_mapping;
}

sub _sam2bam {
    my ($self) = @_;
    my $destination_directory = $self->_destination;

    system(
"samtools view -b -o $destination_directory/mapped.bam -S $destination_directory/mapped.sam"
    );
    return 1;
}

sub _sort_bam {
    my ($self) = @_;
    my $destination_directory = $self->_destination;

    system(
"samtools sort $destination_directory/mapped.bam $destination_directory/mapped.sort"
    );
    system("samtools index $destination_directory/mapped.sort.bam");
    return 1;
}

sub _bamcheck {
    my ($self) = @_;
    my $destination_directory = $self->_destination;

    system(
$self->samtools_exec." stats $destination_directory/mapped.sort.bam > $destination_directory/mapped.bamcheck"
    );
    return 1;
}

sub _make_plot {
    my ($self)                = @_;
    my $destination_directory = $self->_destination;
    my $ref                   = $self->reference;
    my $outfile               = $self->outfile;
    my $tr_d                  = $self->tagdirection;

    my $plot = Bio::Tradis::TradisPlot->new(
        mappedfile    => "$destination_directory/mapped.sort.bam",
        mapping_score => $self->mapping_score,
        outfile       => "$destination_directory/$outfile"
    )->plot;

    # if tag direction is 5, reverse plot columns
    if ( $self->tagdirection eq '5' ) {
        print STDERR "Tag direction = 5. Reversing plot..\n";
        $self->_reverse_plots;
    }
    return 1;
}

sub _reverse_plots {
    my ($self)                = @_;
    my $destination_directory = $self->_destination;
    my $outfile               = $self->outfile;
    my @seqnames              = keys %{ $self->_sequence_info };

    my @current_plots =
      glob("$destination_directory/$outfile.*.insert_site_plot.gz");

    foreach my $plotname (@current_plots) {
        print STDERR "Reversing $plotname\n";

        #my $plotname = $self->_plotname($sn);
        system("gunzip -c $plotname > $destination_directory/tmp.plot");
        system(
"awk '{ t = \$1; \$1 = \$2; \$2 = t; print; }' $destination_directory/tmp.plot > rv_plot"
        );
        system("gzip -c rv_plot > $plotname");
    }
    unlink("$destination_directory/tmp.plot");
    unlink("rv_plot");
}

sub _stats {
    my ($self)                = @_;
    my $outfile               = $self->outfile;
    my $destination_directory = $self->_destination;
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
      `wc $destination_directory/filter.fastq | awk '{print \$1/4}'`;
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
"gunzip -c $destination_directory/$plotname > $destination_directory/tmp.plot"
        );
        my $uis = `grep -c -v "0 0" $destination_directory/tmp.plot`;
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
    my $t_uis_p_l = $total_seq_len / $total_uis;
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
    my $destination_directory = $self->_destination;

    my $pars =
      Bio::Tradis::Parser::Bam->new(
        file => "$destination_directory/mapped.bam" );
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
