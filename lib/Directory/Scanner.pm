package Directory::Scanner;

use strict;
use warnings;

use Directory::Scanner::Stream;
use Directory::Scanner::Stream::Recursive;
use Directory::Scanner::Stream::Filtered;

sub for {
	my (undef, $dir) = @_;

	return bless [ $dir ] => __PACKAGE__;
}

sub recurse {
	my ($builder) = @_;

	push @$builder => [ 'Directory::Scanner::Stream::Recursive' ];

	return $builder;
}

sub filter {
	my ($builder, $filter) = @_;

	push @$builder => [ 'Directory::Scanner::Stream::Filtered', filter => $filter ];

	return $builder;
}

sub stream {
	my ($builder) = @_;

	if ( my $dir = shift @$builder ) {
		my $stream = Directory::Scanner::Stream->new( origin =>  $dir );

		foreach my $layer ( @$builder ) {
			my ($class, %args) = @$layer;
			$stream = $class->new( stream => $stream, %args );
		}

		return $stream;
	}
	else {
		Carp::confess 'Nothing to construct a stream on';
	}
	
}

1;

__END__

=pod

=head1 SYNOPSIS

	Directory::Scanner->for( $dir )->stream;

	Directory::Scanner->for( $dir )
					  ->recurse
					  ->stream;

	Directory::Scanner->for( $dir )
					  ->recurse
					  ->filter(sub { (shift)->is_dir })
					  ->stream;

	Directory::Scanner->for( $dir )
					  ->filter(sub { (shift)->is_dir })
					  ->recurse
					  ->stream;

=cut