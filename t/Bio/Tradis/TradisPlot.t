#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::TradisPlot');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $mappedfile, $obj, $outfile );

$mappedfile = "t/data/TradisPlot/test.mapped.bam";
$outfile    = "test.plot";

ok(
    $obj = Bio::Tradis::TradisPlot->new(
        mappedfile    => $mappedfile,
        outfile       => $outfile,
        mapping_score => 30
    ),
    'creating object'
);

ok( $obj->plot, 'testing plotting' );
ok( -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence' );

system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system("gunzip -c t/data/TradisPlot/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking file contents'
);

unlink('test.plot.AE004091.insert_site_plot.gz');
unlink('expected.plot.unzipped');
done_testing();
