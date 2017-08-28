package Directory::Stream::Recursive;
# ABSTRACT: Recrusive streaming directory iterator 

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
use Directory::Stream::API::Stream;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_STREAM_RECURSIVE_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Stream::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		_stream    => sub {},
		_head      => sub {},	
		_stack     => sub { [] },
		_is_done   => sub { 0 },
		_is_closed => sub { 0 },		
	)
}

## ...

sub BUILDARGS { 
	my $class  = shift;
	my $stream = shift;

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Stream::API::Stream')) 
		|| Carp::confess 'You must supply a directory stream';		

	$class->next::method( _stream => $stream );
}

sub BUILD {
	my ($self, $params) = @_;
	push @{$self->{_stack}} => $self->{_stream};
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new( $self->{_stream}->clone( $dir ) );
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
		$self->log('Entering loop ... ') if DEBUG;

		if ( my $current = $self->{_stack}->[-1] ) {
			$self->log('Stream available in stack') if DEBUG;
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