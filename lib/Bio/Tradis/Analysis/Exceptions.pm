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
