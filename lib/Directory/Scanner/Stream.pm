
use Carp         ();
use Scalar::Util ();
use Path::Tiny   ();

class Directory::Scanner::Stream does Directory::Scanner::API::Stream {

    # constant

    method DEBUG () { $ENV{DIR_SCANNER_STREAM_DEBUG} // 0 }

    ## slots

    has $!origin : ro;

    # internal state ...
    has $!_head;
    has $!_handle;
    has $!_is_done   = 0;
    has $!_is_closed = 0;

    ## ... methods

    method BUILDARGS : strict( origin => $!origin );

    method BUILD ($self, $params) {
    	my $dir = $!origin;

    	# upgrade this to a Path:Tiny
    	# object if needed
    	$!origin = $dir = Path::Tiny::path( $dir )
    		unless Scalar::Util::blessed( $dir )
    			&& $dir->isa('Path::Tiny');

    	# make sure the directory is
    	# fit to be streamed
    	(-d $dir)
    		|| Carp::confess 'Supplied path value must be a directory ('.$dir.')';
    	(-r $dir)
    		|| Carp::confess 'Supplied path value must be a readable directory ('.$dir.')';

    	my $handle;
    	opendir( $handle, $dir )
    		|| Carp::confess 'Unable to open handle for directory('.$dir.') because: ' . $!;

    	$!_handle = $handle;
    }

    ## API::Stream ...

    method head      : ro($!_head);
    method is_done   : ro($!_is_done);
    method is_closed : ro($!_is_closed);

    method close ($self) {
    	closedir( $!_handle )
    		|| Carp::confess 'Unable to close handle for directory because: ' . $!;
    	$!_is_closed = 1;
    	return;
    }

    method next {
    	my $self = $_[0];

    	return if $!_is_done;

    	Carp::confess 'Cannot call `next` on a closed stream'
    		if $!_is_closed;

    	my $next;
    	while (1) {
    		undef $next; # clear any previous values, just cause ...
    		$self->_log('Entering loop ... ') if DEBUG;

    		$self->_log('About to read directory ...') if DEBUG;
    		if ( my $name = readdir( $!_handle ) ) {

    			$self->_log('Read directory ...') if DEBUG;
    			next unless defined $name;

    			$self->_log('Got ('.$name.') from directory read ...') if DEBUG;
    			next if $name eq '.' || $name eq '..'; # skip these ...

    			$next = $!origin->child( $name );

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
    			$!_head    = undef;
    			$!_is_done = 1;
    			last;
    		}
    		$self->_log('... looping') if DEBUG;
    	}

    	$self->_log('Got next value('.$next.')') if DEBUG;
    	return $!_head = $next;
    }


    method clone {
        my ($self, $dir) = @_;
        $dir ||= $!origin;
        return $self->new( origin => $dir );
    }

}

1;

__END__

=pod

=head1 DESCRIPTION

This is provides a stream of a given C<origin> directory.

=head1 METHODS

This object conforms to the C<Directory::Scanner::API::Stream> API.

=cut
