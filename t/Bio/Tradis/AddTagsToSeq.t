#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::AddTagsToSeq');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my $bamfile = "../samples/sample_sm_tr.bam";

ok(
    my $obj = Bio::Tradis::AddTagsToSeq->new(
        bamfile     => $bamfile,
        script_name => 'name_of_script'
    ),
    'testing adding tags to the sequences'
);

done_testing();
