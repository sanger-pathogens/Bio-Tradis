#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use File::Path 'rmtree';
use File::Temp;
use Test::Files qw(compare_ok);

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use Test::Exception;
    use_ok('Bio::Tradis::RunTradis');
}

my $output_directory_obj = File::Temp->newdir( 'tmp_run_tradis_tagless_smalt_tests_XXXXX',
                                               CLEANUP => 0,
                                               DIR => cwd() );
my $output_directory = $output_directory_obj->dirname;
my $temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                             DIR => $output_directory );
my $temp_directory = $temp_directory_obj->dirname();

my ( $obj, $fastqfile, $stats_handle, $ref, $outfile, $aligner);

# First, test all parts and complete pipeline without mismatch

$fastqfile = "t/data/RunTradisTaglessSmalt/notags.fastq";
$ref       = "t/data/RunTradisTaglessSmalt/smallref.fa";
$outfile   = "test.plot";
$aligner   = 1;
open( $stats_handle, '>', "$output_directory/test.stats" );

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile         => $fastqfile,
        reference         => $ref,
        smalt             => $aligner,
        outfile           => $outfile,
        output_directory  => $output_directory,
        _temp_directory   => $temp_directory,
        _stats_handle     => $stats_handle
    ),
    'creating object - Normal files, no mismatch'
);



# Mapping
ok( $obj->_map,                             'testing mapping' );
ok( -e "$temp_directory/mapped.sam", 'checking SAM existence' );
`grep -v "\@PG" $temp_directory/mapped.sam > $output_directory/tmp1.sam`;
`grep -v "\@PG" t/data/RunTradisTaglessSmalt/mapped.sam > $output_directory/tmp2.sam`;
compare_ok( 
    "$output_directory/tmp1.sam", 
    "$output_directory/tmp2.sam",
    'checking mapped file contents' 
);

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
system("gunzip -c t/data/RunTradisTaglessSmalt/expected.plot.gz > $output_directory/expected.plot.unzipped");
compare_ok(
    "$output_directory/test.plot.unzipped",
    "$output_directory/expected.plot.unzipped",
    'checking plot file contents - Normal files, no mismatch'
);


# Complete pipeline
ok( $obj->run_tradis, 'testing complete analysis - Normal files, no mismatch' );
ok( -e "$output_directory/test.plot.AE004091.insert_site_plot.gz",
    'checking plot file existence - Normal files, no mismatch' );
system("gunzip -c $output_directory/test.plot.AE004091.insert_site_plot.gz > $output_directory/test.plot.unzipped");
system("gunzip -c t/data/RunTradisTaglessSmalt/expected.plot.gz > $output_directory/expected.plot.unzipped");
compare_ok(
    "$output_directory/test.plot.unzipped",
    "$output_directory/expected.plot.unzipped",
    'checking completed pipeline file contents - Normal files, no mismatch'
);



unlink("$output_directory/test.plot.AE004091.insert_site_plot.gz");
unlink("$output_directory/expected.plot.unzipped");
unlink("$output_directory/test.plot.unzipped");



# Test mapping stage with custom smalt parameters
$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile        => $fastqfile,
        reference        => $ref,
        smalt            => $aligner,
        outfile          => $outfile,
        output_directory => $output_directory,
        _temp_directory  => $temp_directory,
        _stats_handle    => $stats_handle,
        smalt_k          => 10,
        smalt_s          => 2
    ),
    'creating object with custom smalt parameters'
);

ok( $obj->_map, 'mapping with custom parameters fine' );

# Check die if ref is not found
$temp_directory_obj = File::Temp->newdir( CLEANUP => 0,
                                          DIR => $output_directory );
$temp_directory = $temp_directory_obj->dirname();
ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile        => $fastqfile,
        reference        => "not_really_a_ref.fa",
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
