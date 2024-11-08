
use v5.40;
use experimental qw[ class ];

use Carp         ();
use Scalar::Util ();
use Path::Tiny   ();

class Directory::Scanner::Stream :isa(Directory::Scanner::API::Stream) {
    use constant DEBUG => $ENV{DIR_SCANNER_STREAM_DEBUG} // 0;

    field $origin :param :reader;

    field $head      :reader;
    field $handle    :reader;
    field $is_done   :reader = false;
    field $is_closed :reader = false;

    ADJUST {
        # upgrade this to a Path:Tiny
        # object if needed
        $origin = Path::Tiny::path( $origin )
            unless blessed $origin
                && $origin isa Path::Tiny;

        # make sure the directory is
        # fit to be streamed
        (-d $origin)
            || Carp::confess 'Supplied path value must be a directory ('.$origin.')';
        (-r $origin)
            || Carp::confess 'Supplied path value must be a readable directory ('.$origin.')';

        opendir( $handle, $origin )
            || Carp::confess 'Unable to open handle for directory('.$origin.') because: ' . $!;
    }

    method clone ($dir=undef) {
        __CLASS__->new( origin => $dir // $origin )
    }

    method close {
    	closedir( $handle )
    		|| Carp::confess 'Unable to close handle for directory because: ' . $!;
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

    		$self->_log('About to read directory ...') if DEBUG;
    		if ( my $name = readdir( $handle ) ) {

    			$self->_log('Read directory ...') if DEBUG;
    			next unless defined $name;

    			$self->_log('Got ('.$name.') from directory read ...') if DEBUG;
    			next if $name eq '.' || $name eq '..'; # skip these ...

    			$next = $origin->child( $name );

    			# directory is not readable or has been removed, so skip it
    			if ( ! -r $next ) {
    				$self->_log('Directory/File not readable ...') if DEBUG;
    				next;
    			}
    			else {
    				$self->_log('Value is good, ready to return it') if DEBUG;
    				last;
    			}
    		}
    		else {
    			$self->_log('Exiting loop ... DONE') if DEBUG;

    			# cleanup ...
    			$head    = undef;
    			$is_done = 1;
    			last;
    		}
    		$self->_log('... looping') if DEBUG;
    	}

    	$self->_log('Got next value('.$next.')') if DEBUG;
    	return $head = $next;
    }
}


__END__

=pod

=head1 DESCRIPTION

This is provides a stream of a given C<origin> directory.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
