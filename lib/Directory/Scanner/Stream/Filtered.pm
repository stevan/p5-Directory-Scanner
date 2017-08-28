package Directory::Scanner::Stream::Filtered;
# ABSTRACT: Recrusive streaming directory iterator 

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use UNIVERSAL::Object;
use Directory::Scanner::API::Stream;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_FILTERED_DEBUG} // 0;

## ...

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object', 'Directory::Scanner::API::Stream') }
our %HAS; BEGIN {
	%HAS = (
		stream => sub {},
		filter => sub {},		
	)
}

## ...

sub BUILD { 
	my $self   = $_[0];
	my $stream = $self->{stream};
	my $filter = $self->{filter};

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Scanner::API::Stream')) 
		|| Carp::confess 'You must supply a directory stream';		

	(defined $filter)
		|| Carp::confess 'You must supply a filter';

	(ref $filter eq 'CODE')
		|| Carp::confess 'The filter supplied must be a CODE reference';		
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new( 
		stream => $self->{stream}->clone( $dir ), 
		filter => $self->{filter} 
	);
}

## delegate 

sub head      { $_[0]->{stream}->head      }
sub is_done   { $_[0]->{stream}->is_done   }
sub is_closed { $_[0]->{stream}->is_closed }
sub close     { $_[0]->{stream}->close     }

sub next {
	my $self = $_[0];

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->log('Entering loop ... ') if DEBUG;
		
		$next = $self->{stream}->next;

		# this means the stream is likely 
		# exhausted, so jump out of the loop
		last unless defined $next;

		# now try to filter the value
		# and redo the loop if it does 
		# not pass
		next unless $self->{filter}->( $next );

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