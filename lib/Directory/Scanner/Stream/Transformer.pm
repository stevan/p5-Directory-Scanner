use Carp         ();
use Scalar::Util ();

module Directory::Scanner;

class Stream::Transformer does API::Stream {

    # constant

    const DEBUG = $ENV{DIR_SCANNER_STREAM_TRANSFORMER_DEBUG} // 0;

    ## slots

	has $.stream;
	has $.transformer;

    # internal state ...
	has $!_head;

    ## ...

    method BUILD ($params) {

    	(Scalar::Util::blessed($.stream) && $.stream->roles::DOES('Directory::Scanner::API::Stream'))
    		|| Carp::confess 'You must supply a directory stream';

    	(defined $.transformer)
    		|| Carp::confess 'You must supply a `transformer` value';

    	(ref $.transformer eq 'CODE')
    		|| Carp::confess 'The `transformer` value supplied must be a CODE reference';
    }

    method clone ($dir) {
    	return $self->new(
    		stream      => $.stream->clone( $dir ),
    		transformer => $.transformer
    	);
    }

    ## delegate

    method head      : ro($!_head);
    method is_done   { $.stream->is_done   }
    method is_closed { $.stream->is_closed }
    method close     { $.stream->close     }

    method next {

    	# skip out early if possible
    	return if $.stream->is_done;

    	$self->_log('... calling next on underlying stream') if DEBUG;
    	my $next = $.stream->next;

    	# this means the stream is likely exhausted
    	unless ( defined $next ) {
    		$!_head = undef;
    		return;
    	}

    	$self->_log('got value from stream'.$next.', transforming it now') if DEBUG;

    	# return the result of the Fmap
        local $_ = $next;
    	return $!_head = $.transformer->( $next );
    }
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
