package Directory::Scanner;
# ABSTRACT: Streaming directory scanner

use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

use Directory::Scanner::API::Stream;

use Directory::Scanner::Stream;
use Directory::Scanner::Stream::Concat;

use Directory::Scanner::Stream::Recursive;
use Directory::Scanner::Stream::Filtered;
use Directory::Scanner::Stream::Application;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

## static builder constructors 

sub for {
	my (undef, $dir) = @_;
	return bless [ $dir ] => __PACKAGE__;
}

sub concat {
	my (undef, @streams) = @_;

	Carp::confess 'You provide at least two streams to concat'
		if scalar @streams < 2;

	return Directory::Scanner::Stream::Concat->new( streams => [ @streams ] );
}

## builder instance methods 

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

sub apply {
	my ($builder, $f) = @_;
	push @$builder => [ 'Directory::Scanner::Stream::Application', f => $f ];
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

	# get all entries in a directory 
	
	Directory::Scanner->for( $dir )->stream;

	# get all entries in a directory recursively
	
	Directory::Scanner->for( $dir )
					  ->recurse
					  ->stream;

	# get all entries in a directory recusively 
	# and filter out anything that is not a directory
	
	Directory::Scanner->for( $dir )
					  ->recurse
					  ->filter(sub { (shift)->is_dir })
					  ->stream;

	# get all entries in a directory, filter out 
	# anything that is a . directory, then recurse

	Directory::Scanner->for( $dir )
					  ->filter(sub { (shift)->basename =~ /^\./ })
					  ->recurse
					  ->stream;


=cut


