#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use Test::Files;

BEGIN { 
        unshift( @INC, '../lib' );
        unshift( @INC, './lib' );
}

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::Map');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $fastqfile, $ref, $obj, $refname, $outfile );

$fastqfile = "t/data/Map/test.fastq";
$ref       = "t/data/Map/smallref.fa";
$refname   = "t/data/Map/test.ref";
$outfile   = "t/data/Map/mapped.out";

ok(
    $obj = Bio::Tradis::Map->new(
        fastqfile => $fastqfile,
        reference => $ref,
        refname   => $refname,
        outfile   => $outfile
    ),
    'creating object'
);
ok( $obj->index_ref,              'testing reference indexing' );
ok( -e 't/data/Map/test.ref.sma', 'checking index file existence' );
ok( -e 't/data/Map/test.ref.smi', 'checking index file existence' );

ok( $obj->do_mapping,           'testing reference indexing' );
ok( -e 't/data/Map/mapped.out', 'checking index file existence' );
system("grep -v ^\@ t/data/Map/mapped.out > mapped.nohead.out");
system("grep -v ^\@ t/data/Map/expected.mapped > expected.nohead.mapped");
compare_ok(
    'mapped.nohead.out',
    'expected.nohead.mapped',
    'checking file contents'
);

# test optional smalt parameters
ok(
    $obj = Bio::Tradis::Map->new(
        fastqfile => $fastqfile,
        reference => $ref,
        refname   => $refname,
        outfile   => $outfile,
        smalt_k   => 10,
        smalt_s   => 10,
        smalt_y   => 0.9
    ),
    'creating object'
);

my $index_cmd = $obj->index_ref;
my $index_exp = "smalt index -k 10 -s 10 $refname $ref > /dev/null 2>&1";
is( $index_cmd, $index_exp, "indexing args correct" );

my $map_cmd = $obj->do_mapping;
my $map_exp = "smalt map -n 1 -x -r -1 -y 0.9 $refname $fastqfile 1> $outfile  2> smalt.stderr";
is( $map_cmd, $map_exp, "mapping args correct" );



unlink('t/data/Map/test.ref.sma');
unlink('t/data/Map/test.ref.smi');
unlink('t/data/Map/mapped.out');
done_testing();
