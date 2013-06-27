#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::RunTradis');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 0 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $obj, $fastqfile, $ref, $tag, $outfile );

$fastqfile = "t/data/RunTradis/test.tagged.fastq";
$ref       = "t/data/RunTradis/smallref.fa";
$tag       = "taagagtcag";
$outfile   = "test.plot";

ok(
    $obj = Bio::Tradis::RunTradis->new(
        fastqfile   => $fastqfile,
        reference   => $ref,
        tag         => $tag,
        outfile     => $outfile,
        destination => $destination_directory_obj
    ),
    'creating object'
);

# Filtering step
ok( $obj->_filter, 'testing filtering step' );
ok(
    -e "$destination_directory/filter.fastq",
    'checking filtered file existence'
);
is(
    read_file("$destination_directory/filter.fastq"),
    read_file('t/data/RunTradis/filtered.fastq'),
    'checking filtered file contents'
);

# Tag removal
ok( $obj->_remove, 'testing tag removal' );
ok( -e "$destination_directory/tags_removed.fastq",
    'checking de-tagged file existence' );
is(
    read_file("$destination_directory/tags_removed.fastq"),
    read_file('t/data/RunTradis/notags.fastq'),
    'checking de-tagged file contents'
);

# Mapping
ok( $obj->_map,                             'testing mapping' );
ok( -e "$destination_directory/mapped.sam", 'checking SAM existence' );
`grep -v "\@PG" $destination_directory/mapped.sam > tmp1.sam`;
`grep -v "\@PG" t/data/RunTradis/mapped.sam > tmp2.sam`;
is(
    read_file("tmp1.sam"),
    read_file('tmp2.sam'),
    'checking mapped file contents'
);

# Conversion
ok( $obj->_sam2bam,                         'testing SAM/BAM conversion' );
ok( -e "$destination_directory/mapped.bam", 'checking BAM existence' );

# Plot
ok( $obj->_make_plot, 'testing plotting' );
ok( -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence' );
system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system("gunzip -c t/data/TradisPlot/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking file contents'
);

# Complete pipeline
ok( $obj->run_tradis, 'testing complete analysis' );
ok( -e 'test.plot.AE004091.insert_site_plot.gz',
    'checking plot file existence' );
system("gunzip -c test.plot.AE004091.insert_site_plot.gz > test.plot.unzipped");
system("gunzip -c t/data/TradisPlot/expected.plot.gz > expected.plot.unzipped");
is(
    read_file('test.plot.unzipped'),
    read_file('expected.plot.unzipped'),
    'checking file contents'
);


unlink("tmp1.sam");
unlink("tmp2.sam");
unlink('test.plot.AE004091.insert_site_plot.gz');
unlink('expected.plot.unzipped');
File::Temp::cleanup();
done_testing();
