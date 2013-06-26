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
$tag     = "CAACGTTTT";

ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile   => $fastqfile,
        tag         => $tag,
        outfile     => 't/data/output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags,        'testing output' );
ok( -e 't/data/output.fastq', 'checking file existence' );
is(
    read_file('t/data/output.fastq'),
    read_file('t/data/FilterTags/expected.caa.fastq'),
    'checking file contents'
);

$tag = "TNAGAGACAG";

ok(
    $obj = Bio::Tradis::FilterTags->new(
        fastqfile   => $fastqfile,
        tag         => $tag,
        script_name => 'name_of_script',
        outfile     => 't/data/output.fastq'
    ),
    'creating object'
);
ok( $obj->filter_tags,        'testing output' );
ok( -e 't/data/output.fastq', 'checking file existence' );
is(
    read_file('t/data/output.fastq'),
    read_file('t/data/FilterTags/expected.tna.fastq'),
    'checking file contents'
);

unlink('t/data/output.fastq');
unlink('t/data/FilterTags/expected.caa.fastq');
unlink('t/data/FilterTags/expected.tna.fastq');
done_testing();
