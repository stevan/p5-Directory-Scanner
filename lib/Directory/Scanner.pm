
use v5.40;

use Carp         ();
use Scalar::Util ();

use Directory::Scanner::API::Stream;

use Directory::Scanner::Stream;
use Directory::Scanner::Stream::Application;
use Directory::Scanner::Stream::Concat;
use Directory::Scanner::Stream::Ignoring;
use Directory::Scanner::Stream::Matching;
use Directory::Scanner::Stream::Recursive;
use Directory::Scanner::Stream::Transformer;

package Directory::Scanner {

    sub for ($, $dir) {
        Directory::Scanner::Stream->new( origin =>  $dir );
    }

    sub concat ($, @streams) {
        Carp::confess 'You must provide at least two streams to concat'
            if scalar @streams < 2;
        Directory::Scanner::Stream::Concat->new( streams => [ @streams ] );
    }
}

1;

__END__

=pod

=head1 SYNOPSIS

    # get all entries in a directory

    my $stream = Directory::Scanner->for( $dir );

    # get all entries in a directory recursively

    my $stream = Directory::Scanner->for( $dir )
                                   ->recurse;

    # get all entries in a directory recusively
    # and filter out anything that is not a directory

    my $stream = Directory::Scanner->for( $dir )
                                   ->recurse
                                   ->match(sub { $_->is_dir });

    # ignore anything that is a . directory, then recurse

    my $stream = Directory::Scanner->for( $dir )
                                   ->ignore(sub { $_->basename =~ /^\./ })
                                   ->recurse;

=head1 DESCRIPTION

This module provides a streaming interface for traversing directories.
Unlike most modules that provide similar capabilities, this will not
pre-fetch the list of files or directories, but instead will only focus
on one thing at a time. This is useful if you have a large directory tree
and need to do a lot of resource intensive work on each file.

=head2 Builders

This module uses the builder pattern to create the L<Directory::Scanner>
stream you need. If you look in the L<SYNOPSIS> above you can see that
the C<for> method starts the creation of a builder. All the susequent
chained methods simply wrap the original stream and perform the task
needed.

=head2 Streams

See the "API METHODS" section of L<Directory::Scanner::API::Stream>.

=head1 METHODS

=head2 C<for($dir)>

Constructs a stream for scanning the given C<$dir>.

=head2 C<concat(@streams)>

This concatenates multiple streams into a single stream, and
will return an instance that concats the streams together.

=cut


