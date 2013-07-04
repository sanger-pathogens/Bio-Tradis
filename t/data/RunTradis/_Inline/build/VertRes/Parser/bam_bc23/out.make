/Users/cc21/perl5/perlbrew/perls/perl-5.18.0/bin/perl /Users/cc21/perl5/perlbrew/perls/perl-5.18.0/lib/5.18.0/ExtUtils/xsubpp  -typemap "/Users/cc21/perl5/perlbrew/perls/perl-5.18.0/lib/5.18.0/ExtUtils/typemap"   bam_bc23.xs > bam_bc23.xsc && mv bam_bc23.xsc bam_bc23.c
cc -c  -I"/Users/cc21/Development/repos/Bio-Tradis/bin" -I/Users/cc21/Development/homebrew/bin/ -D_IOLIB=2 -D_FILE_OFFSET_BITS=64 -O3   -DVERSION=\"0.00\" -DXS_VERSION=\"0.00\"  "-I/Users/cc21/perl5/perlbrew/perls/perl-5.18.0/lib/5.18.0/darwin-2level/CORE"   bam_bc23.c
bam_bc23.xs:5:1: error: expected identifier or '('
<<END_C
^
1 error generated.
make: *** [bam_bc23.o] Error 1
