#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, '../lib' ) }

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
        fastqfile   => $fastqfile,
        reference   => $ref,
        refname => $refname,
        outfile     => $outfile
    ),
    'creating object'
);
ok( $obj->index_ref,        'testing reference indexing' );
ok( -e 't/data/Map/test.ref.sma', 'checking index file existence' );
ok( -e 't/data/Map/test.ref.smi', 'checking index file existence' );

ok( $obj->do_mapping,        'testing reference indexing' );
ok( -e 't/data/Map/mapped.out', 'checking index file existence' );
is(
    read_file('t/data/Map/mapped.out'),
    read_file('t/data/Map/expected.mapped'),
    'checking file contents'
);

unlink('t/data/Map/test.ref.sma');
unlink('t/data/Map/test.ref.smi');
unlink('t/data/Map/mapped.out');
done_testing();
