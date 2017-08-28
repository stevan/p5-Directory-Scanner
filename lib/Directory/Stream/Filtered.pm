package Directory::Stream::Filtered;
# ABSTRACT: Recrusive streaming directory iterator 

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_STREAM_FILTERED_DEBUG} // 0;

## ...

use parent 'Directory::Stream::API::Stream';

## ...

sub new {
	my $class  = shift;
	my $stream = shift;
	my $filter = shift;

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Stream::API::Stream')) 
		|| Carp::confess 'You must supply a directory stream';		

	(defined $filter)
		|| Carp::confess 'You must supply a filter';

	(ref $filter eq 'CODE')
		|| Carp::confess 'The filter supplied must be a CODE reference';		

	return bless {
		_stream => $stream,
		_filter => $filter,
	} => ref $class || $class;
}

## delegate 

sub origin    { $_[0]->{_stream}->origin    }
sub head      { $_[0]->{_stream}->head      }
sub is_done   { $_[0]->{_stream}->is_done   }
sub is_closed { $_[0]->{_stream}->is_closed }
sub close     { $_[0]->{_stream}->close     }

sub next {
	my $self = $_[0];

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->log('Entering loop ... ') if DEBUG;
		
		$next = $self->{_stream}->next;

		# this means the stream is likely 
		# exhausted, so jump out of the loop
		last unless defined $next;

		# now try to filter the value
		# and redo the loop if it does 
		# not pass
		next unless $self->{_filter}->( $next );

		$self->log('Exiting loop ... ') if DEBUG;

		# if we have gotten to this 
		# point, we have a value and
		# want to return it 
		last;
	}

	return $next;
}

1;

__END__

=pod

=cut