#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package cgit;

class cgit : does(Frame::App::cgit::Base) : strict(params);

use utf8;
use v5.40;

use lib 'lib';

use Const::Fast;
use Path::Tiny;
use Getopt::Long qw'GetOptionsFromArray :config bundling auto_abbrev';
use Plack::Runner;
use Cwd qw(getcwd abs_path);

use Frame::App::cgit;
use Frame::App::cgit::Instance;

const our $www => abs_path(getcwd);

field $argv : param;
field $app;
field $builder { Plack::Builder->new }
field $srvpath = path(abs_path);
field $config_file;

field $cliopts : param(dest) : reader = {
    ssl => {
        'ssl'        => 1,
        'ssl-server' => 1
    },

};

ADJUSTPARAMS($params) {
    GetOptionsFromArray(
        $argv, $cliopts,

        'ssl|tls|x509',
        'username=s',
        'password=s',
        'verbose',
        'debug', 'help',
        'version',
        'config-file|config-path=s',
        '<>' => sub ($barearg) {
            state $_set //= 0;
            die "\$ARGV[0] has already been set to '$srvpath'" if $_set != 0;
            $_set = 1 && $srvpath = path($barearg);
        }
    );

    $app = Plack::App::WrapCGI->new(
        script  => "/usr/share/webapps/cgit/cgit.cgi",
        execute => 1
    )->to_app;

    my $section = 'frame-app';

    $app = Frame::App::cgit::config->wrap( $app,
        config => $ENV{ uc($section) . "_CGITRC" }
          // "./etc/${section}-cgitrc" );

    $builder->add_middleware_if(
        sub ($env) { !$env->{REMOTE_ADDR} },
        "Plack::Middleware::ReverseProxy"
    );

    if ( $ENV{PLACK_ENV} eq 'development' ) {
        $builder->add_middleware('Debug');
        $builder->add_middleware('StackTrace');
    }

    $builder->add_middleware(
        "Plack::Middleware::Static",
        path => sub { s!^/s/cgit/!! },
        root => "/usr/share/webapps/cgit/"
    );

    $builder->add_middleware(
        "Plack::Middleware::Static",
        path => sub { s!^/s/!! },
        root => $www
    );

    $builder->mount( '/' => $app );
}

method to_app {
    $builder->to_app;
}

method init : common ( $argv = \@ARGV, %opts) {
    my $self = $class->new( argv => $argv );
    $self;
}

package main;

class main : does(Frame::Base);

use utf8;
use v5.40;

use Frame::Base;

our $cgit    = cgit->init( \@ARGV );
our $cliopts = $cgit->cliopts;
our $app     = $cgit->to_app;

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options( $cliopts->{ssl}->%*, @ARGV );

    if ( $$cliopts{pass} isa 'HASH' && $cliopts->{pass}{crypt} ) {
        ...;
    }

    $runner->run($app);

    dmsg( { runner => $runner, app => $app } );

    warn "$! ($?)" if $? != 0;
    exit $?;
}

return $app;
