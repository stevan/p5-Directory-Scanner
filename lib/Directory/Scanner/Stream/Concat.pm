use Carp         ();
use Scalar::Util ();

class Directory::Scanner::Stream::Concat does Directory::Scanner::API::Stream {

    # constant

    method DEBUG () { $ENV{DIR_SCANNER_STREAM_CONCAT_DEBUG} // 0 }

    ## slots

	has $!streams    = [];
	# internal state ...
	has $!_index     = 0;
	has $!_is_done   = 0;
	has $!_is_closed = 0;

    ## ...

    method BUILDARGS : strict( streams => $!streams );

    method BUILD ($self, $params) {

    	(Scalar::Util::blessed($_) && $_->roles::DOES('Directory::Scanner::API::Stream'))
    		|| Carp::confess 'You must supply all directory stream objects'
    			foreach $!streams->@*;
    }

    method clone {
    	# TODO - this might be possible ...
    	Carp::confess 'Cloning a concat stream is not a good idea, just dont do it';
    }

    ## delegate

    method head ($self) {
    	return if $!_index > (scalar $!streams->@* - 1);
    	return $!streams->[ $!_index ]->head;
    }

    method is_done   : ro($!_is_done);
    method is_closed : ro($!_is_closed);

    method close ($self) {
    	foreach my $stream ( $!streams->@* ) {
    		$stream->close;
    	}
    	$!_is_closed = 1;
    	return
    }

    method next ($self) {

    	return if $!_is_done;

    	Carp::confess 'Cannot call `next` on a closed stream'
    		if $!_is_closed;

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		if ( $!_index > (scalar $!streams->@* - 1) ) {
    			# end of the streams now ...
    			$!_is_done = 1;
    			last;
    		}

    		my $current = $!streams->[ $!_index ];

    		if ( $current->is_done ) {
    			# if we are done, advance the
    			# index and restart the loop
    			$!_index++;
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

1;

__END__

=pod

=head1 DESCRIPTION

Given multiple streams, this will concat them together one
after another.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
