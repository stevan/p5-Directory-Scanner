package Directory::Scanner::API::Stream;
# ABSTRACT: Streaming directory iterator abstract interface

use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub head;

sub is_done;
sub is_closed;

sub close;
sub next;

sub clone;

sub recurse {
	my $self = $_[0];
	require Directory::Scanner::Stream::Recursive;
	Directory::Scanner::Stream::Recursive->new( stream => $self );
}

sub filter {
	my $self   = $_[0];
	my $filter = $_[1];
	require Directory::Scanner::Stream::Filtered;
	Directory::Scanner::Stream::Filtered->new( stream => $self, filter => $filter );
}

## ...

# ... shhh, I shouldn't do this 
sub log {
	my ($self, @msg) = @_;
    warn( @msg, "\n" );
    return;
}

1;

__END__

=pod

=cut