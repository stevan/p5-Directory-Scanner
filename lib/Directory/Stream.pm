package Directory::Stream;
# ABSTRACT: Streaming directory iterator 

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();
use Path::Tiny   ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use constant DEBUG => $ENV{DIR_STREAM_DEBUG} // 0;

## ...

use parent 'Directory::Stream::API::Stream';

## ...

sub new {
	my $class = shift;
	my $dir   = shift;

	(defined $dir) 
		|| Carp::confess 'You must supply a directory path';		

	$dir = Path::Tiny::path( $dir ) 
		unless Scalar::Util::blessed( $dir ) 
			&& $dir->isa('Path::Tiny');

	(-d $dir)
		|| Carp::confess 'Supplied path value must be a directory ('.$dir.')';

	(-r $dir) 
		|| Carp::confess 'Supplied path value must be a readable directory ('.$dir.')';

	(! -l $dir)
		|| Carp::confess 'Supplied path value must not be a symlink ('.$dir.')';

	my $handle;
	opendir( $handle, $dir )
		|| Carp::confess 'Unable to open handle for directory('.$dir.') because: ' . $!;

	return bless {
		_origin    => $dir,
		_head      => undef,		
		_handle    => $handle,
		_is_done   => 0,
		_is_closed => 0,
	} => ref $class || $class;
}

## accessor 

sub origin { $_[0]->{_origin} }
sub head   { $_[0]->{_head}   }

sub is_done   { $_[0]->{_is_done}   }
sub is_closed { $_[0]->{_is_closed} }

sub close {
	closedir( $_[0]->{_handle} )
		|| Carp::confess 'Unable to close handle for directory because: ' . $!;
	$_[0]->{_is_closed} = 1;
	return;
}

sub next {
	my $self = $_[0];

	return if $self->{_is_done};

	Carp::confess 'Cannot call `next` on a closed stream'
		if $self->{_is_closed};

	my $next;
	while (1) {
		undef $next; # clear any previous values, just cause ...
		$self->log('Entering loop ... ') if DEBUG;

		$self->log('About to read directory ...') if DEBUG;
		if ( my $name = readdir( $self->{_handle} ) ) {

			$self->log('Read directory ...') if DEBUG;
			next unless defined $name;

			$self->log('Got ('.$name.') from directory read ...') if DEBUG;
			next if $name eq '.' || $name eq '..'; # skip these ...

			$next = $self->{_origin}->child( $name );		

			# directory is not readable or has been removed, so skip it
			if ( ! -r $next ) {
				$self->log('Directory/File not readable ...') if DEBUG;
				next;
			}
			else {
				$self->log('Value is good, ready to return it') if DEBUG;
				last;
			}
		}
		else {
			$self->log('Exiting loop ... DONE') if DEBUG;

			# cleanup ...
			$self->{_head}    = undef;
			$self->{_is_done} = 1;
			last;
		}
		$self->log('... looping') if DEBUG;
	}

	$self->log('Got next value('.$next.')') if DEBUG;
	return $self->{_head} = $next;
}

1;

__END__

=pod

=cut