#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package cgit;

class cgit : does(Frame::Base);

use utf8;
use v5.40;

use lib 'lib';

use Frame::App::cgit ();

field $builder = Plack::Builder->new;

method $run {

}

method init {

}

package main;

class main;

use utf8;
use v5.40;

use Frame::App::cgit::Base qw( dmsg );

our $cgit    = cgit->init( \@ARGV );
our $cliopts = $cgit->cliopts;
our $app     = $cgit->to_app;

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);

    if ( $$cliopts{pass} isa 'HASH' && $cliopts->{pass}{crypt} ) {
        ...;
    }

    $runner->run($app);

    dmsg( { runner => $runner, app => $app } );

    warn "$! ($?)" if $? != 0;
    exit $?;
}

return $app;
