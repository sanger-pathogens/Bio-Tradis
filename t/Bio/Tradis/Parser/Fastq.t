#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::Parser::Fastq');
}

my ( $obj, $fastqfile );

$fastqfile = "t/data/Parsers/test.fastq";

ok(
    $obj = Bio::Tradis::Parser::Fastq->new(
        file => $fastqfile,
    ),
    'creating object'
);
isa_ok $obj, 'Bio::Tradis::Parser::Fastq';

# Test reading first result
is $obj->next_read, 1, 'first result detected';
my @read_info = $obj->read_info; 
is_deeply \@read_info,
  [
    'HS21_09876:1:1105:9650:48712#83',
    'TAAGAGTCAGGGGTCGGCAGACCGACCCTCATGGAAACCCCGGCCTGGCGCCGG',
    'CCCFFFFFHHHHCEE8EEFGFFGFIFGGFGEEHFFFGGGFGFGEGEEEFGFGFF'
  ],
  'read_info contains correct info for first line';

# Test reading second/last result
is $obj->next_read, 1, 'last result detected';
@read_info = $obj->read_info;
is_deeply \@read_info,
  [
    'HS21_09876:1:1106:8638:38957#83',
    'TAAGAGTCAGGGGTCGGCAGACCGACCCTCATGGAAACCCCGGCCTGGCGCCGG',
    'B@CFFFFFHHHHCEF7FHFFFFGFEGEFFEHEGEGFGGGEGFGFGGFEHGFEFD'
  ],
  'read_info contains correct info for last line';

# Ensure end of file is detected
is $obj->next_read, 0, 'EOF detected';

done_testing();
