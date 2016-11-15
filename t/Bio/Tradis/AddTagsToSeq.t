#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use Test::Files qw(compare_ok);

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

is($obj->_output_switch, '-b', 'correctly select the bam output switch');

ok( $obj->add_tags_to_seq,  'testing output' );
ok( -e 't/data/output.bam', 'checking file existence' );
`$samtools_exec view -h -o t/data/output.sam t/data/output.bam`;
`$samtools_exec view -h -o t/data/AddTags/expected_tradis.sam t/data/AddTags/expected_tradis.bam`;
compare_ok(
    't/data/output.sam',
    't/data/AddTags/expected_tradis.sam',
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

compare_ok (
    't/data/AddTags/sample_sm_no_tr.sam',
    't/data/output.sam',
    'checking file contents'
);

is(
    6,
    $obj->_number_of_lines_in_bam_file('t/data/AddTags/sample_sm_no_tr.bam'),
    'number of reads as expected'
);

my $cramfile = "t/data/AddTags/sample_sm_tr.cram";

ok(
    $obj = Bio::Tradis::AddTagsToSeq->new(
        bamfile     => $cramfile,
        script_name => 'name_of_script',
        outfile     => 't/data/output.cram'
    ),
    'creating object with cram file'
);

is($obj->_output_switch, '-C', 'correctly select the cram output switch');

ok( $obj->add_tags_to_seq,  'testing output' );
ok( -e 't/data/output.cram', 'checking file existence' );
`$samtools_exec view -h -o t/data/output.sam t/data/output.cram`;
`$samtools_exec view -h -o t/data/AddTags/expected_tradis.sam t/data/AddTags/expected_tradis.cram`;
compare_ok(
    't/data/output.sam',
    't/data/AddTags/expected_tradis.sam',
    'checking file contents'
);


unlink('t/data/output.cram');
unlink('t/data/output.bam');
unlink('t/data/output.sam');
unlink('t/data/AddTags/expected_tradis.sam');
unlink('t/data/AddTags/sample_sm_no_tr.sam');
done_testing();
