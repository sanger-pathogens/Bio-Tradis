use ExtUtils::MakeMaker;
my %options = %{
{
  'NAME' => 'VertRes::Parser::bam_bc23',
  'INC' => '-I"/Users/cc21/Development/repos/Bio-Tradis/bin" -I/Users/cc21/Development/homebrew/bin/',
  'TYPEMAPS' => [
    '/Users/cc21/perl5/perlbrew/perls/perl-5.18.0/lib/5.18.0/ExtUtils/typemap'
  ],
  'CCFLAGS' => ' -D_IOLIB=2 -D_FILE_OFFSET_BITS=64',
  'VERSION' => '0.00',
  'LIBS' => [
    '-L/Users/cc21/Development/homebrew/bin/ -lbam -lz'
  ]
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
