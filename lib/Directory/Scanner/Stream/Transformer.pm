
use v5.40;
use experimental qw[ class ];

use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Transformer :isa(Directory::Scanner::API::Stream) {
    use constant DEBUG => $ENV{DIR_SCANNER_STREAM_TRANSFORMER_DEBUG} // 0;

    field $stream      :param :reader;
    field $transformer :param :reader;

    field $head :reader;

    ADJUST {
    	(blessed $stream && $stream isa Directory::Scanner::API::Stream)
    		|| Carp::confess 'You must supply a directory stream';

    	(defined $transformer)
    		|| Carp::confess 'You must supply a `transformer` value';

    	(ref $transformer eq 'CODE')
    		|| Carp::confess 'The `transformer` value supplied must be a CODE reference';
    }

    method clone ($dir) {
    	__CLASS__->new(
    		stream      => $stream->clone( $dir ),
    		transformer => $transformer
    	)
    }

    ## delegate

    method is_done   { $stream->is_done   }
    method is_closed { $stream->is_closed }
    method close     { $stream->close     }

    method next {
    	# skip out early if possible
    	return if $stream->is_done;

    	$self->_log('... calling next on underlying stream') if DEBUG;
    	my $next = $stream->next;

    	# this means the stream is likely exhausted
    	unless ( defined $next ) {
    		$head = undef;
    		return;
    	}

    	$self->_log('got value from stream'.$next.', transforming it now') if DEBUG;

    	# return the result of the Fmap
        local $_ = $next;
    	return $head = $transformer->( $next );
    }
}

__END__

=pod

=head1 DESCRIPTION

This is provides a stream that will transform each item using the
given C<transformer> CODE ref.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
