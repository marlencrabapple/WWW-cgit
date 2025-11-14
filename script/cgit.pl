#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package cgit;
use lib 'lib';

class cgit : does(Frame::Base);

use utf8;
use v5.40;

use lib 'lib';

use Data::Dumper;
use Const::Fast         qw( const );
use Path::Tiny          qw( path );
use Getopt::Long        qw( GetOptionsFromArray );
use Plack::Runner       ();
use Plack::Builder      ();
use Plack::App::WrapCGI ();
use Cwd                 qw( abs_path getcwd );

use Frame::App::cgit           ();
use Frame::App::cgit::Instance ();

const our $www => abs_path(getcwd);

field $argv : param;
field $app;
field @instance;
field $builder { Plack::Builder->new }
field $srvpath = path(abs_path);
field $config_file;
field $config : reader = { instance => ['frameapp'] };

field $cliopts : param(dest) : reader = {
    ssl => {
        'ssl'        => 1,
        'ssl-server' => 1
    }
};

ADJUSTPARAMS($params) {
    $self->setup_cgit;

    GetOptionsFromArray(
        $argv, $cliopts,

        #    'ssl|tls|x509',
        'username=s',
        "password=s%",

        #'password=s',
        'verbose',
        'debug', 'help',
        'version',
        'config-file|config-path=s',

    );

    $self->mount_middleware;
    $builder->mount( '/' => shift @instance );

    my $frameapp;
    $builder->mount( '/new' => $frameapp )
}

method mount_middleware {
    $builder->add_middleware_if(
        sub ($env) { !$env->{REMOTE_ADDR} },
        "Plack::Middleware::ReverseProxy"
    );

    if ( $ENV{PLACK_ENV} && ( $ENV{PLACK_ENV} ne 'development' ) ) {
        $builder->add_middleware('Debug');
        $builder->add_middleware('StackTrace');
    }

    # $builder->add_middleware(
    #     "Plack::Middleware::Rewrite",
    #     request => sub {
    #         s^(.+?)\.git(\/)?$^$1/.git^i;
    #     }
    # );

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

}

method setup_cgit () {
    $app = Plack::App::WrapCGI->new(
        script  => "/usr/share/webapps/cgit/cgit.cgi",
        execute => 1
    )->to_app;

    foreach my $instance ( $self->config->{instance}->@* ) {

        push @instance,
          Frame::App::cgit::Instance->wrap( $app,
            config => $ENV{ uc($instance) . "_CGITRC" }
              // "./etc/${instance}-cgitrc" );

        say STDERR Dumper( instance => \@instance, app => $app );
    }

    { baseapp => $app, instances => \@instance };
}

method to_app {
    $builder->to_app;
}

method init : common ( $argv = \@ARGV, %opts) {
    my $self = $class->new( argv => $argv );
    $self;
}

package main;

class main;
use lib 'lib';

use utf8;
use v5.40;

use Data::Dumper;
use Frame::Base;

our $cgitsrv = cgit->init( \@ARGV );
our $cliopts = $cgitsrv->cliopts;
our $app     = $cgitsrv->to_app;

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);

    if ( $$cliopts{pass} isa 'HASH' && $cliopts->{pass}{crypt} ) {
        ...;
    }

    $runner->run($app);

    warn "$! ($?)" if $? != 0;
    exit $?;
}

return $app;
