package Directory::Scanner::Stream::Transformer;
# ABSTRACT: Fmap a streaming directory iterator

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_SCANNER_STREAM_TRANSFORMER_DEBUG} // 0;

## ...

use parent 'UNIVERSAL::Object';
use roles 'Directory::Scanner::API::Stream';
use slots (
	stream      => sub {},
	transformer => sub {},
	# internal state ...
	_head      => sub {},
);

## ...

sub BUILD {
	my $self   = $_[0];
	my $stream = $self->{stream};
	my $f      = $self->{transformer};

	(Scalar::Util::blessed($stream) && $stream->roles::DOES('Directory::Scanner::API::Stream'))
		|| Carp::confess 'You must supply a directory stream';

	(defined $f)
		|| Carp::confess 'You must supply a `transformer` value';

	(ref $f eq 'CODE')
		|| Carp::confess 'The `transformer` value supplied must be a CODE reference';
}

sub clone {
	my ($self, $dir) = @_;
	return $self->new(
		stream      => $self->{stream}->clone( $dir ),
		transformer => $self->{transformer}
	);
}

## delegate

sub head      { $_[0]->{_head}             }
sub is_done   { $_[0]->{stream}->is_done   }
sub is_closed { $_[0]->{stream}->is_closed }
sub close     { $_[0]->{stream}->close     }

sub next {
	my $self = $_[0];

	# skip out early if possible
	return if $self->{stream}->is_done;

	$self->_log('... calling next on underlying stream') if DEBUG;
	my $next = $self->{stream}->next;

	# this means the stream is likely exhausted
	unless ( defined $next ) {
		$self->{_head} = undef;
		return;
	}

	$self->_log('got value from stream'.$next.', transforming it now') if DEBUG;

	# return the result of the Fmap
    local $_ = $next;
	return $self->{_head} = $self->{transformer}->( $next );
}

1;

__END__

=pod

=head1 DESCRIPTION

This is provides a stream that will transform each item using the
given C<transformer> CODE ref.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
