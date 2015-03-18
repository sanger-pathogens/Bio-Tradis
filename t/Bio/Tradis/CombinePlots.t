#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use Cwd;
use File::Path qw( remove_tree );

BEGIN { unshift( @INC, '../lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::Tradis::CombinePlots');
}

my ( $plotfile, $obj );

$plotfile = "t/data/CombinePlots/comb_sample.txt";

ok( $obj = Bio::Tradis::CombinePlots->new( plotfile => $plotfile ),
    'creating object' );

ok( $obj->combine, 'combining plots' );
ok(
    -e 'combined/first.insert_site_plot.gz',
    'checking first combined plot file exists'
);
ok(
    -e 'combined/second.insert_site_plot.gz',
    'checking second combined plot file exists'
);
ok(
	-e 'comb_sample.stats',
	'checking stats file exists'
);

system("gunzip -c combined/first.insert_site_plot.gz > first.test.plot");
is(
    read_file('first.test.plot'),
    read_file('t/data/CombinePlots/first.expected.plot'),
    'checking first file contents'
);
system("gunzip -c combined/second.insert_site_plot.gz > second.test.plot");
is(
    read_file('second.test.plot'),
    read_file('t/data/CombinePlots/second.expected.plot'),
    'checking second file contents'
);
is(
	read_file('comb_sample.stats'),
	read_file('t/data/CombinePlots/comb_expected.stats'),
	'checking stats file contents'
);

#check with gzipped plots
$plotfile = "t/data/CombinePlots/zip_comb_list.txt";

ok( $obj = Bio::Tradis::CombinePlots->new( plotfile => $plotfile ),
    'creating object' );

ok( $obj->combine, 'combining plots' );
ok(
    -e 'combined/zip_combined.insert_site_plot.gz',
    'checking first combined plot file exists'
);
system("gunzip -c combined/zip_combined.insert_site_plot.gz > zip_combined.test.plot");
is(
    read_file('zip_combined.test.plot'),
    read_file('t/data/CombinePlots/zip_comb_exp.plot'),
    'checking zipped file contents'
);
is(
	read_file('zip_comb_list.stats'),
	read_file('t/data/CombinePlots/zip_comb_exp.stats'),
	'checking stats file contents'
);

# check custom directory name
$plotfile = "t/data/CombinePlots/comb_sample.txt";
ok( $obj = Bio::Tradis::CombinePlots->new( 
        plotfile     => $plotfile,
        combined_dir => 'comb_test' 
    ),
    'creating object' 
);

ok( $obj->combine, 'combining plots' );
ok( -d 'comb_test', 'checking directory exists' );
ok(
    -e 'comb_test/first.insert_site_plot.gz',
    'checking first combined plot file exists'
);
ok(
    -e 'comb_test/second.insert_site_plot.gz',
    'checking second combined plot file exists'
);

cleanup_files();
done_testing();

sub cleanup_files {
    unlink('first.test.plot');
    unlink('second.test.plot');
    unlink('zip_combined.test.plot');
    unlink('comb_sample.stats');
    unlink('zip_comb_list.stats');
    remove_tree('combined');
    remove_tree('comb_test');
}