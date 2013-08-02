
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308",
  "AUTHOR" => "Carla Cummins <cc21\@sanger.ac.uk>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Bio-Tradis",
  "EXE_FILES" => [
    "bin/add_tradis_tags",
    "bin/bacteria_tradis",
    "bin/check_tradis_tags",
    "bin/filter_tradis_tags",
    "bin/remove_tradis_tags",
    "bin/tradis_plot"
  ],
  "LICENSE" => "gpl",
  "NAME" => "Bio::Tradis",
  "PREREQ_PM" => {
    "Bio::DB::Sam" => 0,
    "Bio::Seq" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Exception::Class" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "Moose" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Env::Path" => 0,
    "File::Slurp" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "1.132140",
  "test" => {
    "TESTS" => "t/*.t t/Bio/Tradis/*.t t/Bio/Tradis/Analysis/*.t t/Bio/Tradis/Parser/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



