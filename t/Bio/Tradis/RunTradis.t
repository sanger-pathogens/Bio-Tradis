#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Tradis::RunTradis');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 0 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $obj, $fastqfile, $stats_handle, $ref, $tag, $outfile );

# First, test all parts and complete pipeline without mismatch

$fastqfile = "t/data/RunTradis/test.tagged.fastq";
$ref       = "t/data/RunTradis/smallref.fa";
$tag       = "TAAGAGTCAG";
$outfile   = "test.plot";
open( $stats_handle, '>', "test.stats" );

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile     => $fastqfile,
        reference     => $ref,
        tag           => $tag,
        outfile       => $outfile,
        _destination  => $destination_directory_obj->dirname,
        _stats_handle => $stats_handle
    ),
    'creating object - Normal files, no mismatch'
);

# Filtering step
ok( $obj->_filter, 'testing filtering step' );
ok(
    -e "$destination_directory/filter.fastq",
    'checking filtered file existence - Normal files, no mismatch'
);
is(
    read_file("$destination_directory/filter.fastq"),
    read_file('t/data/RunTradis/filtered.fastq'),
    'checking filtered file contents - Normal files, no mismatch'
);

# Tag removal
ok( $obj->_remove, 'testing tag removal' );
ok( -e "$destination_directory/tags_removed.fastq",
    'checking de-tagged file existence - Normal files, no mismatch' );
is(
    read_file("$destination_directory/tags_removed.fastq"),
    read_file('t/data/RunTradis/notags.fastq'),
    'checking de-tagged file contents - Normal files, no mismatch'
);

# Mapping
ok( $obj->_map,                             'testing mapping' );
ok( -e "$destination_directory/mapped.sam", 'checking SAM existence' );
`grep -v "\@PG" $destination_directory/mapped.sam > tmp1.sam`;
`grep -v "\@PG" t/data/RunTradis/mapped.sam > tmp2.sam`;
is( read_file("tmp1.sam"), read_file('tmp2.sam'),
    'checking mapped file contents' );

# Conversion
ok( $obj->_sam2bam,                         'testing SAM/BAM conversion' );
ok( -e "$destination_directory/mapped.bam", 'checking BAM existence' );

# Sorting
ok( $obj->_sort_bam, 'testing BAM sorting' );
ok( -e "$destination_directory/mapped.sort.bam",
    'checking sorted BAM existence - Normal files, no mismatch' );
ok( -e "$destination_directory/mapped.sort.bam.bai",
    'checking indexed BAM existence - Normal files, no mismatch' );

#Bamcheck
ok( $obj->_bamcheck, 'testing bamcheck' );
ok( -e "$destination_directory/mapped.bamcheck",
    'checking bamcheck file existence - Normal files, no mismatch' );

# Plot
ok( $obj->_make_plot, 'testing plotting' );
ok( -e "$destination_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence - Normal files, no mismatch' );
system(
"gunzip -c $destination_directory/test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped"
);
system("gunzip -c t/data/RunTradis/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking plot file contents - Normal files, no mismatch'
);


# Complete pipeline
ok( $obj->run_tradis, 'testing complete analysis - Normal files, no mismatch' );
ok( -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence - Normal files, no mismatch' );
system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system("gunzip -c t/data/RunTradis/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking completed pipeline file contents - Normal files, no mismatch'
);

unlink("$destination_directory/filter.fastq");
unlink("$destination_directory/tags_removed.fastq");

unlink('test.plot.AE004091.insert_site_plot.gz');
unlink('expected.plot.unzipped');
unlink('test.plot.unzipped');

# Test complete pipeline with 1 mismatch allowed

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile     => $fastqfile,
        reference     => $ref,
        tag           => $tag,
        outfile       => $outfile,
        mismatch      => 1,
        _destination  => $destination_directory_obj->dirname,
        _stats_handle => $stats_handle
    ),
    'creating object - Normal files one mismatch'
);

ok( $obj->run_tradis, 'testing complete analysis with mismatch' );
ok( -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence - Normal files one mismatch' );
system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system(
    "gunzip -c t/data/RunTradis/expected.1mm.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking completed pipeline with mismatch file contents - Normal files one mismatch'
);

unlink("tmp1.sam");
unlink("tmp2.sam");
unlink('test.plot.AE004091.insert_site_plot.gz');
unlink('expected.plot.unzipped');
unlink('test.plot.unzipped');

# Test pipeline with gzipped input
$fastqfile = "t/data/RunTradis/test.tagged.fastq.gz";
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile     => $fastqfile,
        reference     => $ref,
        tag           => $tag,
        outfile       => $outfile,
        _destination  => $destination_directory_obj->dirname,
        _stats_handle => $stats_handle
    ),
    'creating object with gzipped data - Normal files one mismatch'
);

ok( $obj->run_tradis, 'testing complete analysis with gzipped data' );
ok(
    -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence (gzipped data) - Normal files one mismatch'
);
ok( -e 'test.plot.mapped.bam', 'checking mapped bam existence - Normal files one mismatch');
ok( -e 'test.plot.mapped.bam.bai', 'checking indexed bam file - Normal files one mismatch');

system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system("gunzip -c t/data/RunTradis/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking completed pipeline with gzipped data file contents - Normal files one mismatch'
);

# Test mapping stage with custom smalt parameters
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile     => $fastqfile,
        reference     => $ref,
        tag           => $tag,
        outfile       => $outfile,
        _destination  => $destination_directory_obj->dirname,
        _stats_handle => $stats_handle,
		smalt_k       => 10,
		smalt_s       => 2
    ),
    'creating object with custom smalt parameters'
);
# Filtering step
$obj->_filter;
$obj->_remove;
ok( $obj->_map, 'mapping with custom parameters fine' );

# Check die if ref is not found
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile     => $fastqfile,
        reference     => "not_really_a_ref.fa",
        tag           => $tag,
        outfile       => $outfile,
        _destination  => $destination_directory_obj->dirname,
        _stats_handle => $stats_handle,
		smalt_k       => 10,
		smalt_s       => 2
    ),
    'creating object with custom smalt parameters'
);
throws_ok {$obj->run_tradis} 'Bio::Tradis::Exception::RefNotFound', 'correct error thrown'; 


File::Temp::cleanup();
done_testing();
