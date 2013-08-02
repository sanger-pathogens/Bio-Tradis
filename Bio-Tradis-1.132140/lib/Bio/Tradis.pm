use strict;
use warnings;
package Bio::Tradis;

# ABSTRACT: Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

1;

__END__

=pod

=head1 NAME

Bio::Tradis - Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

=head1 VERSION

version 1.132140

=head1 SYNOPSIS
Bio-Tradis provides functionality to:
* detect TraDIS tags in a BAM file
* add the tags to the reads
* filter reads in a FastQ file containing a user defined tag
* remove tags
* map to a reference genome
* create an insertion site plot file
available as standalone scripts or as perl modules.

=head1 AUTHOR

Carla Cummins <cc21@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
