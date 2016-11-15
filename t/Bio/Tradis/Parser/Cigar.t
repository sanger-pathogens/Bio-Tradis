#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::Parser::Cigar');
}

my ( $obj, $fastqfile );

my @cigar_tests = (
    {
        name  => 'all matching',
        cigar => '100M',
        coord => 100,
        start => 100,
        end   => 199,
    },
    {
        name  => 'nothing matching',
        cigar => '*',
        coord => 1000,
        start => 0,
        end   => 0,
    },
    {
        name  => 'soft clipping at start',
        cigar => '10S90M',
        coord => 100,
        start => 110,
        end   => 199,
    },
    {
        name  => 'soft clipping at end',
        cigar => '90M10S',
        coord => 100,
        start => 100,
        end   => 189,
    },
    {
        name  => 'soft clipping at both ends',
        cigar => '10S80M10S',
        coord => 100,
        start => 110,
        end   => 189,
    },
    {
        name    => 'deletion in middle',
        'cigar' => '20M1D80M',
        'coord' => 20,
        'end'   => 120,
        'start' => 20
    },
    {
        name    => 'insertions and deletions',
        'cigar' => '27M1I6M1D66M',
        'coord' => 46,
        'end'   => 145,
        'start' => 46
    },
    {
        name    => 'insertions in the middle',
        'cigar' => '90M1I9M',
        'coord' => 80,
        'end'   => 178,
        'start' => 80
    }

);

for my $cigar_test (@cigar_tests) {
    ok( $obj = Bio::Tradis::Parser::Cigar->new( coordinate => $cigar_test->{coord}, cigar => $cigar_test->{cigar} ),
        'initialise obj -' . $cigar_test->{name} );
    is( $obj->start, $cigar_test->{start}, 'read start -' . $cigar_test->{name} );
    is( $obj->end,   $cigar_test->{end},   'read end -' . $cigar_test->{name} );
}

done_testing();
