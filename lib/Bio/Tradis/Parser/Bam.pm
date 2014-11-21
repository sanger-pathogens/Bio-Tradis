package Bio::Tradis::Parser::Bam;

# ABSTRACT: Very basic BAM parser. Limited functionality.

=head1 SYNOPSIS

Parses BAM files and gives access to basic info in them.

   use Bio::Tradis::Parser::Bam;
   
   my $pipeline = Bio::Tradis::Parser::Bam->new(file => 'abc');
   $pipeline->read_info;
   $pipeline->next_read;
   $pipeline->seq_info;
   $pipeline->is_mapped;
   $pipeline->is_reverse;
   
=cut

use Moose;

has 'file' => ( is => 'rw', isa => 'Str', required => 1 );
has '_bam_handle' => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 0,
    lazy     => 1,
    builder  => '_build__bam_handle'
);
has '_currentread' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 0,
    writer   => '_set_currentread'
);

### Private methods ###

sub _build__bam_handle {
    my ($self) = @_;
    my $bamfile = $self->file;

    open( my $bamh, "-|", "samtools view $bamfile" )
      or die "Cannot open $bamfile";
    return $bamh;
}

sub _binary_flag {
    my ( $self, $flag ) = @_;
    my $bin_flag = sprintf( "%b", int($flag) );
    return $bin_flag;
}

sub _parse_read {
    my ( $self, $line ) = @_;
	chomp($line);

    # Parse and return as a hash ref
    my @fields = qw(QNAME FLAG RNAME POS MAPQ CIGAR RNEXT PNEXT TLEN SEQ QUAL);
    my @cols = split( '\t', $line );
    my %read;
	$read{'READ'} = $line;
    foreach my $i ( 0 .. ( scalar(@cols) - 1 ) ) {
        if ( $i < scalar(@fields) ) {
            $read{ $fields[$i] } = $cols[$i];
            if ( $fields[$i] eq 'FLAG' ) {
                $read{'BINARY_FLAG'} = $self->_binary_flag( int( $cols[$i] ) );
            }
        }
        else {
			$cols[$i] =~ /^([^:]+):[AifZHB]:(.+)/;
            #my @tagged = split( ':', $cols[$i] );
			#my $tag_key = shift @tagged;
			#shift @tagged;
            #$read{ $tag_key } = join(':', @tagged);
			$read{ $1 } = $2;
        }
    }
    return \%read;
}

### Public methods ###

=seq_info
Reads BAM header and returns a hash (keys are sequence ids, values are hash
refs with keys as tags (like LN and M5))
=cut

sub seq_info {
    my ($self) = @_;
    my $bamfile = $self->file;

    my ( %all_seq_info, $seq_name, %this_seq_info );
    open( SINFO, "-|", "samtools view -H $bamfile | grep ^\@SQ | cut -f 2-" );
    while ( my $line = <SINFO> ) {
        chomp($line);
        my @fields = split( '\t', $line );
        $seq_name = shift(@fields);
		$seq_name =~ s/SN://;
        foreach my $item (@fields) {
            my @parts = split( ':', $item );
            my $tag = shift(@parts);
            $this_seq_info{$tag} = join( ':', @parts );
			foreach my $k (keys %this_seq_info){
				$all_seq_info{$seq_name}->{$k} = $this_seq_info{$k};
			}
        }
        
    }
    return %all_seq_info;
}

=next_read
Moves _currentread to the next entry in the BAM. Returns 0 if EOF.
=cut

sub next_read {
    my ($self) = @_;
    my $bh     = $self->_bam_handle;
    my $line   = <$bh>;
    if ( defined($line) ) {
        chomp($line);
        my $read = $self->_parse_read($line);
        $self->_set_currentread($read);
        return 1;
    }
    else {
        return 0;
    }
}

sub close_file_handle{
	my ($self) = @_;
	close $self->_bam_handle;
}

=read_info
Returns info from _currentread = hash reference with field name as key. 
Standard fields are named as per the SAM format specification:
1 : QNAME
2 : FLAG
3 : RNAME
4 : POS
5 : MAPQ
6 : CIGAR
7 : RNEXT
8 : PNEXT
9 : TLEN
10 : SEQ
11 : QUAL
Additional fields will use their tag names.
Complete line is returned with key READ
=cut

sub read_info {
    my ($self) = @_;
    return $self->_currentread;
}

=is_mapped
Parses the flag for the current read and determines if mapped.
Returns 0 or 1.
=cut

sub is_mapped {
    my ($self) = @_;
    my $flag = ${ $self->_currentread }{BINARY_FLAG};
    my @flag_array = split( '', $flag );
    my $resl;
    if   ( $flag_array[-3] ) { $resl = 0; }
    else                     { $resl = 1; }
    return $resl;
}

=is_reverse
Parses the flag for the current read and determines if reverse 
complemented. Returns 0 or 1.
=cut

sub is_reverse {
    my ($self) = @_;
    my $flag = ${ $self->_currentread }{BINARY_FLAG};
    my @flag_array = split( '', $flag );

    #print @flag_array;
    return $flag_array[-5];
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
