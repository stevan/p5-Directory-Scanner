package Directory::Scanner::API::Stream;
# ABSTRACT: Streaming directory iterator abstract interface

use strict;
use warnings;

use Directory::Scanner::Stream::Recursive;
use Directory::Scanner::Stream::Matching;
use Directory::Scanner::Stream::Ignoring;
use Directory::Scanner::Stream::Application;
use Directory::Scanner::Stream::Transformer;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

sub head;

sub is_done;
sub is_closed;

sub close;
sub next;

sub clone; # ( $dir => Path::Tiny )

## ...

sub flatten {
	my ($self) = @_;
	my @results;
	while ( my $next = $self->next ) {
		push @results => $next;
	}
	return @results;
}

sub recurse {
    my ($self) = @_;
    Directory::Scanner::Stream::Recursive->new( stream => $self );
}

sub ignore {
    my ($self, $filter) = @_;
    Directory::Scanner::Stream::Ignoring->new( stream => $self, filter => $filter );
}

sub match {
    my ($self, $predicate) = @_;
    Directory::Scanner::Stream::Matching->new( stream => $self, predicate => $predicate );
}

sub apply {
    my ($self, $function) = @_;
    Directory::Scanner::Stream::Application->new( stream => $self, function => $function );
}

sub transform {
    my ($self, $transformer) = @_;
    Directory::Scanner::Stream::Transformer->new( stream => $self, transformer => $transformer );
}

## ...

# shhh, I shouldn't do this
sub _log {
	my ($self, @msg) = @_;
    warn( @msg, "\n" );
    return;
}

1;

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
