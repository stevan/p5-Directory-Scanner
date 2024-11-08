
use v5.40;
use experimental qw[ class ];

use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Concat :isa(Directory::Scanner::API::Stream) {
    use constant DEBUG => $ENV{DIR_SCANNER_STREAM_CONCAT_DEBUG} // 0;

    field $streams :param :reader;

    field $index     :reader = 0;
    field $is_done   :reader = false;
    field $is_closed :reader = false;

    ADJUST {
    	(blessed $_ && $_ isa Directory::Scanner::API::Stream)
    		|| Carp::confess 'You must supply all directory stream objects'
    			foreach @$streams;
    }

    method clone {
    	# TODO - this might be possible ...
    	Carp::confess 'Cloning a concat stream is not a good idea, just dont do it';
    }

    ## delegate

    method head {
    	return if $index > $#{$streams};
    	return $streams->[ $index ]->head;
    }

    method close {
    	foreach my $stream ( @$streams ) {
    		$stream->close;
    	}
    	$is_closed = true;
    	return
    }

    method next {
    	return if $is_done;

    	Carp::confess 'Cannot call `next` on a closed stream'
    		if $is_closed;

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		if ( $index > $#{$streams} ) {
    			# end of the streams now ...
    			$is_done = true;
    			last;
    		}

    		my $current = $streams->[ $index ];

    		if ( $current->is_done ) {
    			# if we are done, advance the
    			# index and restart the loop
    			$index++;
    			next;
    		}
    		else {
    			$next = $current->next;

    			# if next returns nothing,
    			# then we now done, so
    			# restart the loop which
    			# will trigger the ->is_done
    			# block above and DWIM
    			next unless defined $next;

    			$self->_log('Exiting loop ... ') if DEBUG;

    			# if we have gotten to this
    			# point, we have a value and
    			# want to return it
    			last;
    		}
    	}

    	return $next;
    }
}


__END__

=pod

=head1 DESCRIPTION

Given multiple streams, this will concat them together one
after another.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
