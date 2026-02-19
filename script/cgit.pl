#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package cgit;
use lib 'lib';

class cgit : does(Frame::Base);

use utf8;
use v5.40;

use lib 'lib';

use Const::Fast         qw( const );
use Path::Tiny          qw( path );
use Getopt::Long        qw( GetOptionsFromArray );
use Plack::Runner       ();
use Plack::Builder      ();
use Plack::App::WrapCGI ();
use Cwd                 qw( abs_path getcwd );
use IPC::Nosh;
use IPC::Nosh::IO;

field $argv : param;
field $app;
field $instance = {};
field $builder { Plack::Builder->new }
field $execdir = path(abs_path);
field $cgitrc : reader = [];
field $config_file;
field $sockchown;
field $listen : reader = [':5000'];

field $cliopts : param(dest) : reader = {
    mount   => '/',
    cgitrc  => $cgitrc,
    execdir => $execdir,
    assets  => "$execdir/www",
    listen  => $listen           # [':5000'],        #["$execdir/cgitsrv.sock"]
};

ADJUSTPARAMS($params) {
    const my @instance_optspec => (
        'basicauth|auth|http-basic-auth=s', 'config-file|config-path=s',
        'ssl-cert-file=s',                  'ssl-key-file=s',
        'cgit|cgi|script=s',
    );

    GetOptionsFromArray(
        $argv,          $cliopts,
        'cgitrc=s{,}',  'verbose+',
        'debug+',       'verion',
        'help|usage|?', 'mount=s',
        'listen=s{1,}', 'sockchown|socket-chown=s',
        @instance_optspec
    );

    if ( $$cliopts{sockchown} ) {
        my ( $uname, $group ) = split /:/, $$cliopts{sockchown}, 1;
        $group //= $uname;

        $sockchown =
          { uid => getpwnam($uname), gid => getgrnam($group) };
    }

    foreach my $cgitrc (@$cgitrc) {
        my ( $rcfile, $mount, %opt ) = split /:/, $cgitrc, 1;
        $mount //= '/';

        $$instance{$cgitrc} =
          { %$cliopts, cgit => "/usr/share/webapps/cgit/cgit.cgi", };

        if ( scalar keys %opt ) {
            GetOptionsFromArray( \%opt, $$instance{$cgitrc},
                @instance_optspec );
        }

        $$instance{$cgitrc}{app} = $self->init_instance( $$instance{$cgitrc} );

        $builder->mount( $mount, $$instance{$cgitrc}{app} );
    }

    $self->mount_middleware;
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

    if ( $$cliopts{rewrite} ) {
        $builder->add_middleware(
            "Plack::Middleware::Rewrite",
            request => sub {
                s^(.+?)\.git(\/)?$^$1/.git^i;
            }
        );
    }

    if ( $$cliopts{serve_assets} ) {
        $builder->add_middleware(
            "Plack::Middleware::Static",
            path => sub { s!^/s/cgit/!! },
            root => "/usr/share/webapps/cgit/"
        );

        $builder->add_middleware(
            "Plack::Middleware::Static",
            path => sub { s!^/s/!! },
            root => $$cliopts{assets}
        );
    }
}

method init_instance ($opt) {
    my $app = Plack::App::WrapCGI->new(
        script  => $$opt{cgit},
        execute => 1
    )->to_app;
}

method to_app {
    $builder->to_app;
}

package main;

class main;
use lib 'lib';

use utf8;
use v5.40;

use IPC::Nosh;
use IPC::Nosh::IO;
use Const::Fast;

our $cgitsrv = cgit->new( argv => \@ARGV );
our $app     = $cgitsrv->to_app;

const our $sockscheme_re => qr'^unix://';

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;

    foreach my $listen ( $cgitsrv->listen->@* ) {
        if ( $listen =~ $sockscheme_re ) {
            my $sock = path( $listen =~ s/$sockscheme_re//r );
            $sock->unlink if $sock->exists && !$sock->is_dir;
            chown( $cgitsrv->sockchown->@*->(qw(uid gid)), $sock )
              if $cgitsrv->sockchown;
        }
    }

    $runner->parse_options(@ARGV);
    $runner->run($app);

    warn "$! ($?)" if $? != 0;
    exit $?;
}

return $app;
