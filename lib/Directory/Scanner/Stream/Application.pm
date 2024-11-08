
use v5.40;
use experimental qw[ class ];

use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Application :isa(Directory::Scanner::API::Stream) {
    use constant DEBUG => $ENV{DIR_SCANNER_STREAM_APPLICATION_DEBUG} // 0;

    field $stream   :param :reader;
    field $function :param :reader;

    ADJUST {
    	(blessed $stream && $stream isa Directory::Scanner::API::Stream)
    		|| Carp::confess 'You must supply a directory stream';

    	(defined $function)
    		|| Carp::confess 'You must supply a `function` value';

    	(ref $function eq 'CODE')
    		|| Carp::confess 'The `function` value supplied must be a CODE reference';
    }

    method clone ($dir) {
    	__CLASS__->new(
    		stream   => $stream->clone( $dir ),
    		function => $function
    	)
    }

    ## delegate

    method head      { $stream->head      }
    method is_done   { $stream->is_done   }
    method is_closed { $stream->is_closed }
    method close     { $stream->close     }

    method next {
    	my $next = $stream->next;

    	# this means the stream is likely exhausted
    	return unless defined $next;

    	# apply the function ...
        local $_ = $next;
    	$function->( $next );

    	# return the next value
    	return $next;
    }
}

__END__

=pod

=head1 DESCRIPTION

This is provides a stream that will apply a function to each item
using the given C<function> CODE ref.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
