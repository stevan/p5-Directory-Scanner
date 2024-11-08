
use v5.40;
use experimental qw[ class ];

class Directory::Scanner::API::Stream {

    method head;

    method is_done;
    method is_closed;

    method close;
    method next;

    method clone; # ( $dir => Path::Tiny )

    ## ...

    method flatten {
    	my @results;
    	while ( my $next = $self->next ) {
    		push @results => $next;
    	}
    	return @results;
    }

    method recurse {
        Directory::Scanner::Stream::Recursive->new( stream => $self );
    }

    method ignore ($filter) {
        Directory::Scanner::Stream::Ignoring->new( stream => $self, filter => $filter );
    }

    method match ($predicate) {
        Directory::Scanner::Stream::Matching->new( stream => $self, predicate => $predicate );
    }

    method apply ($function) {
        Directory::Scanner::Stream::Application->new( stream => $self, function => $function );
    }

    method transform ($transformer) {
        Directory::Scanner::Stream::Transformer->new( stream => $self, transformer => $transformer );
    }

    ## ...

    # shhh, I shouldn't do this
    method _log (@msg) {
        warn( @msg, "\n" );
        return;
    }
}

__END__

=pod

=head1 DESCRIPTION

This is a simple API role that defines what a stream object
can do.

=head1 API METHODS

=head2 C<next>

Get the next item in the stream.

=head2 C<head>

The value currently being processed. This is always the
same as the last value returned from C<next>.

=head2 C<is_done>

This indicates that the stream has been exhausted and
that there is no more values to come from next.

This occurs *after* the last call to C<next> that
returned nothing.

=head2 C<close>

This closes a stream and any subsequent calls to C<next>
will throw an error.

=head2 C<is_closed>

This indicates that the stream has been closed, usually
by someone calling the C<close> method.

=head2 C<clone( ?$dir )>

This will clone a given stream and can optionally be
given a different directory to scan.

=head1 UTILITY METHODS

=head2 C<flatten>

This will take a given stream and flatten it into an
array.

=head2 C<recurse>

By default a scanner will not try to recurse into subdirectories,
if that is what you want, you must call this builder method.

See L<Directory::Scanner::Stream::Recursive> for more info.

=head2 C<ignore($filter)>

Construct a stream that will ignore anything that is matched by
the C<$filter> CODE ref.

See L<Directory::Scanner::Stream::Ignoring> for more info.

=head2 C<match($predicate)>

Construct a stream that will keep anything that is matched by
the C<$predicate> CODE ref.

See L<Directory::Scanner::Stream::Matching> for more info.

=head2 C<apply($function)>

Construct a stream that will apply the C<$function> to each
element in the stream without modifying it.

See L<Directory::Scanner::Stream::Application> for more info.

=head2 C<transform($transformer)>

Construct a stream that will apply the C<$transformer> to each
element in the stream and modify it.

See L<Directory::Scanner::Stream::Transformer> for more info.

=cut
