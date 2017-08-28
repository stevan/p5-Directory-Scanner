package Directory::Stream::Recursive;
# ABSTRACT: Recrusive streaming directory iterator 

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_STREAM_RECURSIVE_DEBUG} // 0;

## ...

use parent 'Directory::Stream::API::Stream';

## ...

sub new {
	my $class  = shift;
	my $stream = shift;

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Stream::API::Stream')) 
		|| Carp::confess 'You must supply a directory stream';	

	return bless {
		_origin    => $stream->origin,
		_head      => undef,	
		_stack     => [ $stream ],
		_is_done   => 0,
		_is_closed => 0,		
	} => ref $class || $class;
}

## accessor 

sub origin { $_[0]->{_origin} }
sub head   { $_[0]->{_head}   }

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
		$self->log('Entering loop ... ') if DEBUG;

		if ( my $current = $self->{_stack}->[-1] ) {
			$self->log('Stream available in stack') if DEBUG;
			if ( my $candidate = $current->next ) {
				# if we have a directory, prepare
				# to recurse into it the next time 
				# we are called, then ....
				if ( $candidate->is_dir ) {
					push @{$self->{_stack}} => $current->new( $candidate );
				}
				
				# return our successful candidate 
				$next = $candidate;
				last;
			}
			else {
				$self->log('Current stream has been exhausted, moving to next') if DEBUG;

				# something, something, ... check is_done on $current here ...

				my $old = pop @{$self->{_stack}};
				$old->close unless $old->is_closed;
				next;
			}
		}
		else {
			$self->log('No more streams available in stack') if DEBUG;
			$self->log('Exiting loop ... DONE') if DEBUG;

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

=cut