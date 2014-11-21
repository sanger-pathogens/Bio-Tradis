use strict;
use warnings;
package Bio::Tradis;

# ABSTRACT: Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

=head1 SYNOPSIS

Bio-Tradis provides functionality to:
=over
=item * detect TraDIS tags in a BAM file - L<Bio::Tradis::DetectTags>
=item * add the tags to the reads - L<Bio::Tradis::AddTagsToSeq>
=item * filter reads in a FastQ file containing a user defined tag - L<Bio::Tradis::FilterTags>
=item * remove tags - L<Bio::Tradis::RemoveTags>
=item * map to a reference genome - L<Bio::Tradis::Map>
=item * create an insertion site plot file - L<Bio::Tradis::TradisPlot>
=back
Most of these functions are available as standalone scripts or as perl modules.

=cut
1;
