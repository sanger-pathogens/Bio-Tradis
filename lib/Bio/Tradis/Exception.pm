package Bio::Tradis::Exception;
# ABSTRACT: Exceptions for input data 

=head1 SYNOPSIS

Exceptions for input data 

=cut


use Exception::Class (
    Bio::Tradis::Exception::RefNotFound => { description => 'Cannot find the reference file' }
);  

1;