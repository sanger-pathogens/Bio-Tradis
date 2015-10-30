#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use File::Path 'rmtree';
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Tradis::RunTradis');
}

my $output_directory_obj = File::Temp->newdir( 'tmp_run_tradis_tests_XXXXX',
                                               CLEANUP => 0,
                                               DIR => cwd() );
my $output_directory = $output_directory_obj->dirname;
my $temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                             DIR => $output_directory );
my $temp_directory = $temp_directory_obj->dirname();

my ( $obj, $fastqfile, $stats_handle, $ref, $tag, $outfile );

# First, test all parts and complete pipeline without mismatch

$fastqfile = "t/data/RunTradis/test.tagged.fastq";
$ref       = "t/data/RunTradis/smallref.fa";
$tag       = "TAAGAGTCAG";
$outfile   = "test.plot";
open( $stats_handle, '>', "$output_directory/test.stats" );

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile         => $fastqfile,
        reference         => $ref,
        tag               => $tag,
        outfile           => $outfile,
        output_directory  => $output_directory,
        _temp_directory   => $temp_directory,
        _stats_handle     => $stats_handle
    ),
    'creating object - Normal files, no mismatch'
);

# Filtering step
ok( $obj->_filter, 'testing filtering step' );
ok(
    -e "$temp_directory/filter.fastq",
    'checking filtered file existence - Normal files, no mismatch'
);
is(
    read_file("$temp_directory/filter.fastq"),
    read_file('t/data/RunTradis/filtered.fastq'),
    'checking filtered file contents - Normal files, no mismatch'
);

# Check filtering step
ok( $obj->_check_filter, 'testing check filtering step' );
system("mv $temp_directory/filter.fastq $temp_directory/filter.fastq.bak");
throws_ok {$obj->_check_filter} 'Bio::Tradis::Exception::TagFilterError', 'complain if no filtered reads';
system("touch $temp_directory/filter.fastq");
throws_ok {$obj->_check_filter} 'Bio::Tradis::Exception::TagFilterError', 'complain if filtered reads are empty';
system("echo foo > $temp_directory/filter.fastq");
throws_ok {$obj->_check_filter} 'Bio::Tradis::Exception::TagFilterError', 'complain if filtered reads has less than 4 lines';
system("echo 'foo\nbar\nbaz\nquux' > $temp_directory/filter.fastq");
throws_ok {$obj->_check_filter} 'Bio::Tradis::Exception::TagFilterError', 'complain if filtered reads do not look like a fastq';
system("echo 'foo\nbar\n+' > $temp_directory/filter.fastq");
throws_ok {$obj->_check_filter} 'Bio::Tradis::Exception::TagFilterError', 'complain if filtered reads are too short';
system("echo 'foo\nbar\n+\nquux' > $temp_directory/filter.fastq");
ok( $obj->_check_filter, 'check very basic filtered reads validation');
system("mv $temp_directory/filter.fastq.bak $temp_directory/filter.fastq");

# Tag removal
ok( $obj->_remove, 'testing tag removal' );
ok( -e "$temp_directory/tags_removed.fastq",
    'checking de-tagged file existence - Normal files, no mismatch' );
is(
    read_file("$temp_directory/tags_removed.fastq"),
    read_file('t/data/RunTradis/notags.fastq'),
    'checking de-tagged file contents - Normal files, no mismatch'
);

# Mapping
ok( $obj->_map,                             'testing mapping' );
ok( -e "$temp_directory/mapped.sam", 'checking SAM existence' );
`grep -v "\@PG" $temp_directory/mapped.sam > $output_directory/tmp1.sam`;
`grep -v "\@PG" t/data/RunTradis/mapped.sam > $output_directory/tmp2.sam`;
is( read_file("$output_directory/tmp1.sam"), read_file("$output_directory/tmp2.sam"),
    'checking mapped file contents' );

# Conversion
ok( $obj->_sam2bam,                         'testing SAM/BAM conversion' );
ok( -e "$temp_directory/mapped.bam", 'checking BAM existence' );

# Sorting
ok( $obj->_sort_bam, 'testing BAM sorting' );
ok( -e "$temp_directory/mapped.sort.bam",
    'checking sorted BAM existence - Normal files, no mismatch' );
ok( -e "$temp_directory/mapped.sort.bam.bai",
    'checking indexed BAM existence - Normal files, no mismatch' );

#Bamcheck
ok( $obj->_bamcheck, 'testing bamcheck' );
ok( -e "$temp_directory/mapped.bamcheck",
    'checking bamcheck file existence - Normal files, no mismatch' );

# Plot
ok( $obj->_make_plot, 'testing plotting' );
ok( -e "$temp_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence - Normal files, no mismatch' );
system(
"gunzip -c $temp_directory/test.plot.AE004091.insert_site_plot.gz > $output_directory/test.plot.unzipped"
);
system("gunzip -c t/data/RunTradis/expected.plot.gz > $output_directory/expected.plot.unzipped");
is(
    read_file("$output_directory/test.plot.unzipped"),
    read_file("$output_directory/expected.plot.unzipped"),
    'checking plot file contents - Normal files, no mismatch'
);


# Complete pipeline
ok( $obj->run_tradis, 'testing complete analysis - Normal files, no mismatch' );
ok( -e "$output_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence - Normal files, no mismatch' );
system("gunzip -c $output_directory/test.plot.AE004091.insert_site_plot.gz > $output_directory/test.plot.unzipped");
system("gunzip -c t/data/RunTradis/expected.plot.gz > $output_directory/expected.plot.unzipped");
is(
    read_file("$output_directory/test.plot.unzipped"),
    read_file("$output_directory/expected.plot.unzipped"),
    'checking completed pipeline file contents - Normal files, no mismatch'
);

unlink("$temp_directory/filter.fastq");
unlink("$temp_directory/tags_removed.fastq");

unlink("$output_directory/test.plot.AE004091.insert_site_plot.gz");
unlink("$output_directory/expected.plot.unzipped");
unlink("$output_directory/test.plot.unzipped");

# Test complete pipeline with 1 mismatch allowed

$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile         => $fastqfile,
        reference         => $ref,
        tag               => $tag,
        outfile           => $outfile,
        mismatch          => 1,
        output_directory  => $output_directory,
        _temp_directory   => $temp_directory,
        _stats_handle     => $stats_handle
    ),
    'creating object - Normal files one mismatch'
);

ok( $obj->run_tradis, 'testing complete analysis with mismatch' );
ok( -e "$output_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence - Normal files one mismatch' );
system("gunzip -c $output_directory/test.plot.AE004091.insert_site_plot.gz > $output_directory/test.plot.unzipped");
system(
    "gunzip -c t/data/RunTradis/expected.1mm.plot.gz > $output_directory/expected.plot.unzipped");
is(
    read_file("$output_directory/test.plot.unzipped"),
    read_file("$output_directory/expected.plot.unzipped"),
    'checking completed pipeline with mismatch file contents - Normal files one mismatch'
);

unlink("$output_directory/tmp1.sam");
unlink("$output_directory/tmp2.sam");
unlink("$output_directory/test.plot.AE004091.insert_site_plot.gz");
unlink("$output_directory/expected.plot.unzipped");
unlink("$output_directory/test.plot.unzipped");

# Test pipeline with gzipped input
$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();
$fastqfile = "t/data/RunTradis/test.tagged.fastq.gz";
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile        => $fastqfile,
        reference        => $ref,
        tag              => $tag,
        outfile          => $outfile,
        output_directory => $output_directory,
        _temp_directory  => $temp_directory,
        _stats_handle    => $stats_handle
    ),
    'creating object with gzipped data - Normal files one mismatch'
);

ok( $obj->run_tradis, 'testing complete analysis with gzipped data' );
ok(
    -e "$output_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence (gzipped data) - Normal files one mismatch'
);
ok( -e "$output_directory/test.plot.mapped.bam", 'checking mapped bam existence - Normal files one mismatch');
ok( -e "$output_directory/test.plot.mapped.bam.bai", 'checking indexed bam file - Normal files one mismatch');

system("gunzip -c $output_directory/test.plot.AE004091.insert_site_plot.gz > $output_directory/test.plot.unzipped");
system("gunzip -c t/data/RunTradis/expected.plot.gz > $output_directory/expected.plot.unzipped");
is(
    read_file("$output_directory/test.plot.unzipped"),
    read_file("$output_directory/expected.plot.unzipped"),
    'checking completed pipeline with gzipped data file contents - Normal files one mismatch'
);

# Test mapping stage with custom smalt parameters
$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile        => $fastqfile,
        reference        => $ref,
        tag              => $tag,
        outfile          => $outfile,
        output_directory => $output_directory,
        _temp_directory  => $temp_directory,
        _stats_handle    => $stats_handle,
        smalt_k          => 10,
        smalt_s          => 2
    ),
    'creating object with custom smalt parameters'
);
# Filtering step
$obj->_filter;
$obj->_remove;
ok( $obj->_map, 'mapping with custom parameters fine' );

# Check die if ref is not found
$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile        => $fastqfile,
        reference        => "not_really_a_ref.fa",
        tag              => $tag,
        outfile          => $outfile,
        output_directory => $output_directory,
        _temp_directory  => $temp_directory,
        _stats_handle    => $stats_handle,
        smalt_k          => 10,
        smalt_s          => 2
    ),
    'creating object with custom smalt parameters'
);
throws_ok {$obj->run_tradis} 'Bio::Tradis::Exception::RefNotFound', 'correct error thrown'; 

rmtree($output_directory);
done_testing();
