use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Recursive does Directory::Scanner::API::Stream {

    # constant

    method DEBUG () { $ENV{DIR_SCANNER_STREAM_RECURSIVE_DEBUG} // 0 }

    ## slots

	has $!stream;
	# internal state ...
	has $!_head;
	has $!_stack     = [];
	has $!_is_done   = 0;
	has $!_is_closed = 0;

    ## ...

    method BUILDARGS : strict( stream => $!stream );

    method BUILD ($self, $params) {

    	(Scalar::Util::blessed($!stream) && $!stream->roles::DOES('Directory::Scanner::API::Stream'))
    		|| Carp::confess 'You must supply a directory stream';

    	push $!_stack->@* => $!stream;
    }

    method clone ($self, $dir) {
    	return $self->new( stream => $!stream->clone( $dir ) );
    }

    ## accessor

    method head      : ro($!_head);
    method is_done   : ro($!_is_done);
    method is_closed : ro($!_is_closed);

    method close ($self) {
    	while ( my $stream = pop $!_stack->@* ) {
    		$stream->close;
    	}
    	$!_is_closed = 1;
    	return;
    }

    method next ($self) {

    	return if $!_is_done;

    	Carp::confess 'Cannot call `next` on a closed stream'
    		if $!_is_closed;

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		if ( my $current = $!_stack->[-1] ) {
    			$self->_log('Stream available in stack') if DEBUG;
    			if ( my $candidate = $current->next ) {
    				# if we have a directory, prepare
    				# to recurse into it the next time
    				# we are called, then ....
    				if ( $candidate->is_dir ) {
    					push $!_stack->@* => $current->clone( $candidate );
    				}

    				# return our successful candidate
    				$next = $candidate;
    				last;
    			}
    			else {
    				$self->_log('Current stream has been exhausted, moving to next') if DEBUG;

    				# something, something, ... check is_done on $current here ...

    				my $old = pop $!_stack->@*;
    				$old->close unless $old->is_closed;
    				next;
    			}
    		}
    		else {
    			$self->_log('No more streams available in stack') if DEBUG;
    			$self->_log('Exiting loop ... DONE') if DEBUG;

    			$!_head    = undef;
    			$!_is_done = 1;
    			last;
    		}
    	}

    	return $!_head = $next;
    }
}

1;

__END__

=pod


=head1 DESCRIPTION

This is provides a stream that will traverse all encountered
sub-directories.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
