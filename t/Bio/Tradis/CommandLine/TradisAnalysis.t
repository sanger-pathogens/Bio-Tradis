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

rmtree($output_directory);
done_testing();
