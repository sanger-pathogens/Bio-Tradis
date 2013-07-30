#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::RemoveTags');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $fastqfile, $tag, $obj );

$fastqfile = "t/data/RemoveTags/sample.caa.fastq";
$tag       = "CAACGTTTT";

# Test without mismatch option
ok(
    $obj = Bio::Tradis::RemoveTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 0,
        outfile   => 't/data/output.fastq'
    ),
    'creating object'
);
ok( $obj->remove_tags,        'testing output' );
ok( -e 't/data/output.fastq', 'checking file existence' );
is(
    read_file('t/data/output.fastq'),
    read_file('t/data/RemoveTags/expected.rm.caa.fastq'),
    'checking file contents'
);

# Test with 1 mismatch allowed
ok(
    $obj = Bio::Tradis::RemoveTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 1,
        outfile   => 't/data/output.fastq'
    ),
    'creating object'
);
ok( $obj->remove_tags,        'testing output' );
ok( -e 't/data/output.fastq', 'checking file existence' );
is(
    read_file('t/data/output.fastq'),
    read_file('t/data/RemoveTags/expected.rm.1mm.caa.fastq'),
    'checking file contents'
);

$fastqfile = "t/data/RemoveTags/sample.tna.fastq";
$tag       = "TNAGAGACAG";

ok(
    $obj = Bio::Tradis::RemoveTags->new(
        fastqfile => $fastqfile,
        tag       => $tag,
        mismatch  => 0,
        outfile   => 't/data/output.fastq'
    ),
    'creating object'
);
ok( $obj->remove_tags,        'testing output' );
ok( -e 't/data/output.fastq', 'checking file existence' );
is(
    read_file('t/data/output.fastq'),
    read_file('t/data/RemoveTags/expected.rm.tna.fastq'),
    'checking file contents'
);

unlink('t/data/output.fastq');
unlink('t/data/RemoveTags/expected.rm.caa.fastq');
unlink('t/data/RemoveTags/expected.rm.tna.fastq');
done_testing();
