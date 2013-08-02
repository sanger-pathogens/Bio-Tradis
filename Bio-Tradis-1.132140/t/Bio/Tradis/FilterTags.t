#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::FilterTags');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $fastqfile, $tag, $obj );

$fastqfile = "t/data/FilterTags/sample.fastq";
$tag       = "CAACGTTTT";

ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 0,
        outfile   => 'output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags, 'testing output' );
ok( -e 'output.fastq', 'checking file existence' );
is(
    read_file('output.fastq'),
    read_file('t/data/FilterTags/expected.caa.fastq'),
    'checking file contents'
);

# Test tag mismatch option
ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 1,
        outfile   => 'output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags, 'testing output' );
ok( -e 'output.fastq', 'checking file existence' );
is(
    read_file('output.fastq'),
    read_file('t/data/FilterTags/expected.1mm.caa.fastq'),
    'checking file contents'
);

# Different tag
$tag = "TNAGAGACAG";

ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 0,
        outfile   => 'output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags, 'testing output' );
ok( -e 'output.fastq', 'checking file existence' );
is(
    read_file('output.fastq'),
    read_file('t/data/FilterTags/expected.tna.fastq'),
    'checking file contents'
);

# Gzipped input
$fastqfile = "t/data/FilterTags/sample.fastq.gz";
$tag       = "CAACGTTTT";

ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 0,
        outfile   => 'output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags, 'testing output' );
ok( -e 'output.fastq', 'checking file existence' );
is(
    read_file('output.fastq'),
    read_file('t/data/FilterTags/expected.caa.fastq'),
    'checking file contents'
);

unlink('t/data/output.fastq');
unlink('t/data/FilterTags/expected.caa.fastq');
unlink('t/data/FilterTags/expected.tna.fastq');
done_testing();
