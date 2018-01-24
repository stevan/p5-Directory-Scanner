#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Directory::Scanner');
}

my $ROOT = $FindBin::Bin.'/data/';

subtest '... twisted filtered stream test' => sub {

    my $stream = Directory::Scanner->for( $ROOT )
                                   ->recurse
                                   ->match(sub { $_->is_file });
    isa_ok($stream, 'Directory::Scanner::Stream::Matching');

    ok(!$stream->is_done, '... the stream is not done');
    ok(!$stream->is_closed, '... the stream is not closed');
    ok(!defined($stream->head), '... nothing in the head of the stream');

    my @all;
    for ( 0 .. 2 ) {
        my $i = $stream->next;
        push @all => $i;
        is($i, $stream->head, '... the head is the same as the value returned by next');
    }

    $stream = $stream->transform(sub { $_->relative( $ROOT ) });

    while ( my $i = $stream->next ) {
        push @all => $i;
        is($i, $stream->head, '... the head is the same as the value returned by next');
    }

    is_deeply(
        [ sort @all ],
        [
            "${ROOT}lib/Foo.pm",
            "${ROOT}lib/Foo/Bar.pm",
            "${ROOT}lib/Foo/Bar/Baz.pm",
            qw[
                t/000-load.pl
                t/001-basic.pl
            ]
        ],
        '... got the list of directories'
    );

    ok($stream->is_done, '... the stream is done');
    ok(!$stream->is_closed, '... but the stream is not closed');
    ok(!defined($stream->head), '... nothing in the head of the stream');

    is(exception { $stream->close }, undef, '... closed stream successfully');

    ok($stream->is_closed, '... the stream is closed');
};


done_testing;
