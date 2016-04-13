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
    use_ok('Bio::Tradis::CommandLine::TradisAnalysis');
}

# Tag which is found in both inputs
my $output_directory_obj = File::Temp->newdir( 'tmp_TradisAnalysis_tests_XXXXX',
                                               CLEANUP => 0,
                                               DIR => cwd() );
my $output_directory = $output_directory_obj->dirname;

ok(
    my $obj = Bio::Tradis::CommandLine::TradisAnalysis->new(
              args              => ['-f', 't/data/CommandLine/fastq.list', '-t',
                                    "TAAGAGTCAG", '-r', "t/data/RunTradis/smallref.fa"],
              script_name       => 'bacteria_tradis_test',
              _output_directory => $output_directory
    ),
    'creating object'
);

ok( $obj->run, 'testing run' );

open(STATS, "$output_directory/fastq.stats") or die "Could not open stats file";
my $line_count = 0;
while (<STATS>) { $line_count++; }
is( $line_count, 3, "both files have reads with tag");
rmtree($output_directory);

# Only one file has a read with the given tag
$output_directory_obj = File::Temp->newdir( 'tmp_TradisAnalysis_tests_XXXXX',
                                            CLEANUP => 0,
                                            DIR => cwd() );
$output_directory = $output_directory_obj->dirname;

$obj = Bio::Tradis::CommandLine::TradisAnalysis->new(
       args              => ['-f', 't/data/CommandLine/fastq.list', '-t',
                             "CGCACAGCCG", '-r', "t/data/RunTradis/smallref.fa"],
       script_name       => 'bacteria_tradis_test',
       _output_directory => $output_directory
);

{
    my $warning_counter = 0;
    local $SIG{'__WARN__'} = sub { $warning_counter++; };
    ok( $obj->run, 'testing run with tag only found in one fastq' );
    is( $warning_counter, 1, "one warning raised" );
}
open(STATS, "$output_directory/fastq.stats") or die "Could not open stats file";
$line_count = 0;
while (<STATS>) { $line_count++; }
is( $line_count, 2, "only one input fastq has reads with tag");
rmtree($output_directory);

# Neither fastq input has a read with the given tag
$output_directory_obj = File::Temp->newdir( 'tmp_TradisAnalysis_tests_XXXXX',
                                            CLEANUP => 0,
                                            DIR => cwd() );
$output_directory = $output_directory_obj->dirname;

$obj = Bio::Tradis::CommandLine::TradisAnalysis->new(
       args              => ['-f', 't/data/CommandLine/fastq.list', '-t',
                             "AAAAAAAAAA", '-r', "t/data/RunTradis/smallref.fa"],
       script_name       => 'bacteria_tradis_test',
       _output_directory => $output_directory
);

{
    my $warning_counter = 0;
    local $SIG{'__WARN__'} = sub { $warning_counter++; };
    throws_ok {$obj->run} 'Bio::Tradis::Exception::TagFilterError', 'testing run without tag in either fastq';
    is( $warning_counter, 2, "two warnings raised" );
}
open(STATS, "$output_directory/fastq.stats") or die "Could not open stats file";
$line_count = 0;
while (<STATS>) { $line_count++; }
is( $line_count, 0, "neither input fastq has reads with tag");
rmtree($output_directory);

done_testing();
