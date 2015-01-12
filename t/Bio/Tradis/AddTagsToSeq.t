#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }
BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::AddTagsToSeq');
}
my $samtools_exec = 'samtools';

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

my ( $bamfile, $obj );

$bamfile = "t/data/AddTags/sample_sm_tr.bam";

ok(
    $obj = Bio::Tradis::AddTagsToSeq->new(
        bamfile     => $bamfile,
        script_name => 'name_of_script',
        outfile     => 't/data/output.bam'
    ),
    'creating object'
);
ok( $obj->add_tags_to_seq,  'testing output' );
ok( -e 't/data/output.bam', 'checking file existence' );
`$samtools_exec view -h -o t/data/output.sam t/data/output.bam`;
`$samtools_exec view -h -o t/data/AddTags/expected_tradis.sam t/data/AddTags/expected_tradis.bam`;
is(
    read_file('t/data/output.sam'),
    read_file('t/data/AddTags/expected_tradis.sam'),
    'checking file contents'
);
$bamfile = "t/data/AddTags/sample_sm_no_tr.bam";

ok(
    $obj = Bio::Tradis::AddTagsToSeq->new(
        bamfile     => $bamfile,
        script_name => 'name_of_script',
        outfile     => 't/data/output.bam'
    ),
    'creating object'
);
ok( -e 't/data/output.bam', 'checking file existence' );
`$samtools_exec view -h -o t/data/output.sam t/data/output.bam`;
`$samtools_exec view -h -o t/data/AddTags/sample_sm_no_tr.sam t/data/AddTags/sample_sm_no_tr.bam`;
is(
    read_file('t/data/AddTags/sample_sm_no_tr.sam'),
    read_file('t/data/output.sam'),
    'checking file contents'
);

is(
    6,
    $obj->_number_of_lines_in_bam_file('t/data/AddTags/sample_sm_no_tr.bam'),
    'number of reads as expected'
);

unlink('t/data/output.bam');
unlink('t/data/output.sam');
unlink('t/data/AddTags/expected_tradis.sam');
unlink('t/data/AddTags/sample_sm_no_tr.sam');
done_testing();
