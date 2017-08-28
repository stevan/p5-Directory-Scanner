package Directory::Scanner::Stream::Application;
# ABSTRACT: Apply function to streaming directory iterator 

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
		f      => sub {},		
	)
}

## ...

sub BUILD { 
	my $self   = $_[0];
	my $stream = $self->{stream};
	my $f      = $self->{f};

	(Scalar::Util::blessed($stream) && $stream->DOES('Directory::Scanner::API::Stream')) 
		|| Carp::confess 'You must supply a directory stream';		

	(defined $f)
		|| Carp::confess 'You must supply a `f` value';

	(ref $f eq 'CODE')
		|| Carp::confess 'The `f` value supplied must be a CODE reference';		
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new( 
		stream => $self->{stream}->clone( $dir ), 
		f      => $self->{f} 
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
		$self->_log('Entering loop ... ') if DEBUG;
		
		$next = $self->{stream}->next;

		# this means the stream is likely 
		# exhausted, so jump out of the loop
		last unless defined $next;

		# apply the function ... 
		$self->{f}->( $next );

		$self->_log('Exiting loop ... ') if DEBUG;

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