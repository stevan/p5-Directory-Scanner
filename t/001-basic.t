#!/usr/bin/env perl 

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

BEGIN {
	use_ok('Directory::Stream');
	use_ok('Directory::Stream::Recursive');
	use_ok('Directory::Stream::Filtered');
}

my $ROOT = $FindBin::Bin.'/../';

subtest '... basic stream test' => sub {

	my $stream = Directory::Stream->new( $ROOT );
	isa_ok($stream, 'Directory::Stream');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	my @dirs;
	while ( my $i = $stream->next ) {
		push @dirs => $i->relative( $ROOT );
		is($i, $stream->head, '... the head is the same as the value returned by next');
	}

	is_deeply([ sort @dirs ], [qw[ lib t ]], '... got the list of directories');
	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');
};

subtest '... basic recursive stream test' => sub {

	my $stream = Directory::Stream::Recursive->new(
		Directory::Stream->new( $ROOT )
	);
	isa_ok($stream, 'Directory::Stream::Recursive');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');	

	my @all;
	while ( my $i = $stream->next ) {
		push @all => $i->relative( $ROOT );
		is($i, $stream->head, '... the head is the same as the value returned by next');
	}

	is_deeply(
		[ sort @all ], 
		[qw[ 
			lib 
			lib/Directory
			lib/Directory/Stream
			lib/Directory/Stream.pm				
			lib/Directory/Stream/API
			lib/Directory/Stream/API/Stream.pm					
			lib/Directory/Stream/Filtered.pm
			lib/Directory/Stream/Recursive.pm
			t 
			t/000-load.t
			t/001-basic.t
		]], 
		'... got the list of directories'
	);

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');	
};

subtest '... basic filtered stream test' => sub {

	my $stream = Directory::Stream::Filtered->new(
		Directory::Stream::Recursive->new(
			Directory::Stream->new( $ROOT )
		),
		sub { (shift)->is_dir }
	);
	isa_ok($stream, 'Directory::Stream::Filtered');

	ok(!$stream->is_done, '... the stream is not done');
	ok(!$stream->is_closed, '... the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');	

	my @all;
	while ( my $i = $stream->next ) {
		push @all => $i->relative( $ROOT );
		is($i, $stream->head, '... the head is the same as the value returned by next');
	}

	is_deeply(
		[ sort @all ], 
		[qw[ 
			lib 
			lib/Directory
			lib/Directory/Stream			
			lib/Directory/Stream/API
			t 
		]], 
		'... got the list of directories'
	);

	ok($stream->is_done, '... the stream is done');
	ok(!$stream->is_closed, '... but the stream is not closed');
	ok(!defined($stream->head), '... nothing in the head of the stream');

	is(exception { $stream->close }, undef, '... closed stream successfully');

	ok($stream->is_closed, '... the stream is closed');	
};

done_testing;
