use Carp         ();
use Scalar::Util ();

module Directory::Scanner;

class Stream::Matching does API::Stream {

    # constant

    const DEBUG = $ENV{DIR_SCANNER_STREAM_MATCHING_DEBUG} // 0;

    ## slots

	has $.stream;
	has $.predicate;

    ## ...

    method BUILD ($params) {

    	(Scalar::Util::blessed($.stream) && $.stream->roles::DOES('Directory::Scanner::API::Stream'))
    		|| Carp::confess 'You must supply a directory stream';

    	(defined $.predicate)
    		|| Carp::confess 'You must supply a predicate';

    	(ref $.predicate eq 'CODE')
    		|| Carp::confess 'The predicate supplied must be a CODE reference';
    }

    method clone ($dir) {
    	return $self->new(
    		stream    => $.stream->clone( $dir ),
    		predicate => $.predicate
    	);
    }

    ## delegate

    method head      { $.stream->head      }
    method is_done   { $.stream->is_done   }
    method is_closed { $.stream->is_closed }
    method close     { $.stream->close     }

    method next {

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		$next = $.stream->next;

    		# this means the stream is likely
    		# exhausted, so jump out of the loop
    		last unless defined $next;

    		# now try to predicate the value
    		# and redo the loop if it does
    		# not pass
            local $_ = $next;
    		next unless $.predicate->( $next );

    		$self->_log('Exiting loop ... ') if DEBUG;

    		# if we have gotten to this
    		# point, we have a value and
    		# want to return it
    		last;
    	}

    	return $next;
    }
}

1;

__END__

=pod

=head1 DESCRIPTION

This is provides a stream that will retain any item for which the
given a C<predicate> CODE ref returns true.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
