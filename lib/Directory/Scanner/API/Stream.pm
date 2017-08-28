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

sub clone; # ( $dir => Path::Tiny )

# ... shhh, I shouldn't do this 
sub _log {
	my ($self, @msg) = @_;
    warn( @msg, "\n" );
    return;
}

1;

__END__

=pod

=cut