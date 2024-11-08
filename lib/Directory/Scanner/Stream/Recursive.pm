
use v5.40;
use experimental qw[ class ];

use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Recursive :isa(Directory::Scanner::API::Stream) {
    use constant DEBUG => $ENV{DIR_SCANNER_STREAM_RECURSIVE_DEBUG} // 0;

    field $stream :param :reader;

    field $head      :reader;
    field $is_done   :reader = false;
    field $is_closed :reader = false;

    field @stack;

    ADJUST {
    	(blessed $stream && $stream isa Directory::Scanner::API::Stream)
    		|| Carp::confess 'You must supply a directory stream';

    	push @stack => $stream;
    }

    method clone ($dir) {
    	__CLASS__->new( stream => $stream->clone( $dir ) );
    }

    method close {
    	while ( my $stream = pop @stack ) {
    		$stream->close;
    	}
    	$is_closed = true;
    	return;
    }

    method next {
    	return if $is_done;

    	Carp::confess 'Cannot call `next` on a closed stream'
    		if $is_closed;

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		if ( my $current = $stack[-1] ) {
    			$self->_log('Stream available in stack') if DEBUG;
    			if ( my $candidate = $current->next ) {
    				# if we have a directory, prepare
    				# to recurse into it the next time
    				# we are called, then ....
    				if ( $candidate->is_dir ) {
    					push @stack => $current->clone( $candidate );
    				}

    				# return our successful candidate
    				$next = $candidate;
    				last;
    			}
    			else {
    				$self->_log('Current stream has been exhausted, moving to next') if DEBUG;

    				# something, something, ... check is_done on $current here ...

    				my $old = pop @stack;
    				$old->close unless $old->is_closed;
    				next;
    			}
    		}
    		else {
    			$self->_log('No more streams available in stack') if DEBUG;
    			$self->_log('Exiting loop ... DONE') if DEBUG;

    			$head    = undef;
    			$is_done = true;
    			last;
    		}
    	}

    	return $head = $next;
    }
}

__END__

=pod


=head1 DESCRIPTION

This is provides a stream that will traverse all encountered
sub-directories.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
