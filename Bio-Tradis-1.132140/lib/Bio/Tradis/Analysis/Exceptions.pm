package Bio::Tradis::Analysis::Exceptions;

use Exception::Class (
    Bio::Tradis::Analysis::Exceptions::FailedToOpenAlignmentSlice => { description => 'Couldnt get reads from alignment slice. Error with Samtools or BAM' },
    Bio::Tradis::Analysis::Exceptions::FailedToOpenExpressionResultsSpreadsheetForWriting => { description => 'Couldnt write out the results for expression' },
		Bio::Tradis::Analysis::Exceptions::InvalidInputFiles => { description => 'Invalid inputs, sequence names or lengths are incorrect' },
		Bio::Tradis::Analysis::Exceptions::FailedToCreateNewBAM => { description => 'Couldnt create a new bam file' },
		Bio::Tradis::Analysis::Exceptions::FailedToCreateMpileup => { description => 'Couldnt create an mpileup' },
		Bio::Tradis::Analysis::Exceptions::FailedToOpenFeaturesTabFileForWriting => { description => 'Couldnt write tab file' },
);

1;

__END__

=pod

=head1 NAME

Bio::Tradis::Analysis::Exceptions

=head1 VERSION

version 1.132140

=head1 AUTHOR

Carla Cummins <cc21@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
