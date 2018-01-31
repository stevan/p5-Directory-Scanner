package Directory::Scanner::Stream::Recursive;
# ABSTRACT: Recrusive streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_RECURSIVE_DEBUG} // 0;

## ...

use parent 'UNIVERSAL::Object';
use roles 'Directory::Scanner::API::Stream';
use slots (
	stream     => sub {},
	# internal state ...
	_head      => sub {},
	_stack     => sub { [] },
	_is_done   => sub { 0 },
	_is_closed => sub { 0 },
);

## ...

sub BUILD {
	my ($self, $params) = @_;

	my $stream = $self->{stream};

	(Scalar::Util::blessed($stream) && $stream->roles::DOES('Directory::Scanner::API::Stream'))
		|| Carp::confess 'You must supply a directory stream';

	push @{$self->{_stack}} => $stream;
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new( stream => $self->{stream}->clone( $dir ) );
}

## accessor

sub head { $_[0]->{_head} }

sub is_done   { $_[0]->{_is_done}   }
sub is_closed { $_[0]->{_is_closed} }

sub close {
	my $self = $_[0];
	while ( my $stream = pop @{ $self->{_stack} } ) {
		$stream->close;
	}
	$self->{_is_closed} = 1;
	return;
}

sub next {
	my $self = $_[0];

	return if $self->{_is_done};

	Carp::confess 'Cannot call `next` on a closed stream'
		if $self->{_is_closed};

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->_log('Entering loop ... ') if DEBUG;

		if ( my $current = $self->{_stack}->[-1] ) {
			$self->_log('Stream available in stack') if DEBUG;
			if ( my $candidate = $current->next ) {
				# if we have a directory, prepare
				# to recurse into it the next time
				# we are called, then ....
				if ( $candidate->is_dir ) {
					push @{$self->{_stack}} => $current->clone( $candidate );
				}

				# return our successful candidate
				$next = $candidate;
				last;
			}
			else {
				$self->_log('Current stream has been exhausted, moving to next') if DEBUG;

				# something, something, ... check is_done on $current here ...

				my $old = pop @{$self->{_stack}};
				$old->close unless $old->is_closed;
				next;
			}
		}
		else {
			$self->_log('No more streams available in stack') if DEBUG;
			$self->_log('Exiting loop ... DONE') if DEBUG;

			$self->{_head}    = undef;
			$self->{_is_done} = 1;
			last;
		}
	}

	return $self->{_head} = $next;
}

1;

__END__

=pod


=head1 DESCRIPTION

This is provides a stream that will traverse all encountered
sub-directories.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
