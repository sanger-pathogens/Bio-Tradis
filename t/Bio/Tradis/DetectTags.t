#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::DetectTags');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $bamfile, $obj );

$bamfile = "t/data/DetectTags/sample_sm_tr.bam";

ok(
    $obj = Bio::Tradis::DetectTags->new(
        bamfile     => $bamfile,
        script_name => 'name_of_script'
    ),
    'testing tag checker - tradis'
);
is( $obj->tags_present, 1, 'testing output' );


my $cramfile = "t/data/DetectTags/sample_sm_tr.cram";

ok(
    $obj = Bio::Tradis::DetectTags->new(
        bamfile     => $cramfile,
        script_name => 'name_of_script'
    ),
    'testing tag checker for cram- tradis'
);
is( $obj->tags_present, 1, 'testing output cram' );



$bamfile = "t/data/DetectTags/sample_sm_no_tr.bam";

ok(
    $obj = Bio::Tradis::DetectTags->new(
        bamfile     => $bamfile,
        script_name => 'name_of_script'
    ),
    'testing tag checker - no tradis'
);
is( $obj->tags_present, 0, 'testing output' );

done_testing();
