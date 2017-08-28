package Directory::Scanner;

use strict;
use warnings;

use Directory::Scanner::Stream;
use Directory::Scanner::Stream::Recursive;
use Directory::Scanner::Stream::Filtered;

sub new_stream {
	my (undef, $dir) = @_;

	return Directory::Scanner::Stream->new( origin => $dir );
}

1;

__END__

=pod

=head1 SYNOPSIS

	Directory::Scanner->new_stream( $dir )
					  ->recurse
					  ->filter(sub { (shift)->is_dir });

	my $stream = Directory::Stream::Filtered->new(
		Directory::Scanner->new_stream( $ROOT, recurse => 1 ),
		sub { (shift)->is_dir },
	);

	Directory::Scanner->new_stream( $dir )
					  ->filter(sub { (shift)->is_dir })
					  ->recurse;	

	my $stream = Directory::Stream::Recursive->new(
		Directory::Stream::Filtered->new(
			Directory::Stream->new( $ROOT ),
			sub { (shift)->is_dir }
		)
	);

=cut