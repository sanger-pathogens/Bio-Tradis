#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::Parser::Bam');
}

my ( $obj, $bamfile );

$bamfile = "t/data/Parsers/test.bam";

ok(
    $obj = Bio::Tradis::Parser::Bam->new(
        file => $bamfile,
    ),
    'creating object'
);
isa_ok $obj, 'Bio::Tradis::Parser::Bam';

# Test sequence info
my %si = $obj->seq_info;
is ref( \%si ), 'HASH', 'seq_info returns a hash';

# Test reading first result
is $obj->next_read, 1, 'first result detected';
my $read_info = $obj->read_info;
is_deeply $read_info,
  {
    QNAME       => 'MS5_9521:1:1101:10072:14269#14',
    FLAG        => '16',
    BINARY_FLAG => '10000',
    RNAME       => 'ENA|AE004091|AE004091.2',
    POS         => '5',
    MAPQ        => '37',
    CIGAR       => '50M',
    RNEXT       => '*',
    PNEXT       => '0',
    TLEN        => '0',
    SEQ         => 'AAGAGACCGGCGATTCTAGTGAAATCGAACGGGCAGGTCAATTTCCAACC',
    QUAL        => 'HHHGGGGGGGHHHHHHHHHHHGHHHGHHGGGGGGGGGGFFFBFFCBAABA',
    X0          => '1',
    X1          => '0',
    BC          => 'TCTCGGTT',
    MD          => '50',
    RG          => '1#14',
    XG          => '0',
    NM          => '0',
    XM          => '0',
    XO          => '0',
    QT          => 'BBCDECBC',
    XT          => 'U',
    tq          => 'CCCBBFFFFF',
    tr          => 'TAAGAGTCAG',
    READ        => 'MS5_9521:1:1101:10072:14269#14	16	ENA|AE004091|AE004091.2	5	37	50M	*	0	0	AAGAGACCGGCGATTCTAGTGAAATCGAACGGGCAGGTCAATTTCCAACC	HHHGGGGGGGHHHHHHHHHHHGHHHGHHGGGGGGGGGGFFFBFFCBAABA	X0:i:1	X1:i:0	BC:Z:TCTCGGTT	MD:Z:50	RG:Z:1#14	XG:i:0	NM:i:0	XM:i:0	XO:i:0	QT:Z:BBCDECBC	XT:A:U	tq:Z:CCCBBFFFFF	tr:Z:TAAGAGTCAG'
  },
  'read_info contains correct info for first line';

is $obj->is_mapped,  1, 'testing flag parsing - mapped';
is $obj->is_reverse, 1, 'testing flag parsing - reverse complement';

# Test reading second/last result
is $obj->next_read, 1, 'last result detected';
$read_info = $obj->read_info;
is_deeply $read_info,
  {
    QNAME       => 'MS5_9521:1:1103:26809:18585#14',
    FLAG        => '1040',
    BINARY_FLAG => '10000010000',
    RNAME       => 'ENA|AE004091|AE004091.2',
    POS         => '23',
    MAPQ        => '37',
    CIGAR       => '50M',
    RNEXT       => '*',
    PNEXT       => '0',
    TLEN        => '0',
    SEQ         => 'GTGAAATCGAACGGGCAGGTCAATTTCCAACCAGCGATGACGTAATAGAT',
    QUAL        => '5FGGHHGEGHFEHHHHHGFHHGHGGHGFGGFCGEGBBAFC?DFFFBBBB3',
    X0          => '1',
    X1          => '0',
    BC          => 'TCTCGGTT',
    MD          => '50',
    RG          => '1#14',
    XG          => '0',
    NM          => '0',
    XM          => '0',
    XO          => '0',
    QT          => 'CCCCCCCC',
    XT          => 'U',
    tq          => 'BCCCCFFFFF',
    tr          => 'TAAGAGTCAG',
    READ        => 'MS5_9521:1:1103:26809:18585#14	1040	ENA|AE004091|AE004091.2	23	37	50M	*	0	0	GTGAAATCGAACGGGCAGGTCAATTTCCAACCAGCGATGACGTAATAGAT	5FGGHHGEGHFEHHHHHGFHHGHGGHGFGGFCGEGBBAFC?DFFFBBBB3	X0:i:1	X1:i:0	BC:Z:TCTCGGTT	MD:Z:50	RG:Z:1#14	XG:i:0	NM:i:0	XM:i:0	XO:i:0	QT:Z:CCCCCCCC	XT:A:U	tq:Z:BCCCCFFFFF	tr:Z:TAAGAGTCAG'
  },
  'read_info contains correct info for last line';

# Ensure end of file is detected
is $obj->next_read, 0, 'EOF detected';

done_testing();
