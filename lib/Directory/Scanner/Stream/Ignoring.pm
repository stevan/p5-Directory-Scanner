use Carp         ();
use Scalar::Util ();

module Directory::Scanner;

class Stream::Ignoring does API::Stream {

    # constant

    const DEBUG = $ENV{DIR_SCANNER_STREAM_IGNORING_DEBUG} // 0;

    ## slots

    has $.stream;
    has $.filter;

    ## ...

    method BUILD ($params) {

        (Scalar::Util::blessed($.stream) && $.stream->roles::DOES('Directory::Scanner::API::Stream'))
            || Carp::confess 'You must supply a directory stream';

        (defined $.filter)
            || Carp::confess 'You must supply a filter';

        (ref $.filter eq 'CODE')
            || Carp::confess 'The filter supplied must be a CODE reference';
    }

    method clone ($dir) {
        return $self->new(
            stream => $.stream->clone( $dir ),
            filter => $.filter
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

            # now try to filter the value
            # and redo the loop if it does
            # not pass
            local $_ = $next;
            next if $.filter->( $next );

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

This is provides a stream that will ignore any item for which the
given a C<filter> CODE ref returns true.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
