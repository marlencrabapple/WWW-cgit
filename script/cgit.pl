#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package cgit;
use lib 'lib';

class cgit;

use utf8;
use v5.40;

use lib 'lib';

use Const::Fast         qw( const );
use Path::Tiny          qw( path );
use Getopt::Long        qw(GetOptionsFromArray :config no_ignore_case);
use Plack::Runner       ();
use Plack::Builder      ();
use Plack::App::WrapCGI ();
use Cwd                 qw( abs_path getcwd );

use IPC::Run3;
use IPC::Nosh::IO;

use Frame::App::cgit::Instance;

const our $sockscheme_re => qr'^unix://';

field $argv : param;
field $app;
field $instance = {};
field $builder { Plack::Builder->new }
field $execdir = path(abs_path);
field $cgit_sharedir : accessor = "/usr/share/webapps/cgit";
field $cgitrc        : reader   = [];
field $config_file;
field $sockchown : reader;
field $sockchgrp : reader;
field $sockchmod : reader;
field $listen    : reader = [];
field $sock;

field $cliopts : param(dest) : reader {
    {
        mount           => '/',
        cgitrc          => $cgitrc,
        execdir         => $execdir,
        'cgit-sharedir' => sub { $self->cgit_sharedir(@_) },
        assets          => ["$execdir/www"],
        listen          => $listen,
        'serve-static'  => $ENV{PLACK_ENV} eq 'development'
        ? 1
        : 0    # [':5000'],        #["$execdir/cgitsrv.sock"]
    }
};

ADJUSTPARAMS($params) {
    const my @instance_optspec => (
        'basicauth|auth|http-basic-auth=s', 'config=s',
        'ssl-certfile=s',                   'ssl-keyfile=s',
        'cgit|cgi|script=s',
    );

    GetOptionsFromArray(
        $argv,                      $cliopts,
        'cgitrc=s{,}',              'verbose+',
        'debug+',                   'verion',
        'help|usage|?',             'mount=s',
        'listen=s{1,}',             'sockchown|socket-chown=s',
        'sockchgrp|socket-chgrp=s', 'sockchmod|socket-chmod=s',
        'static|assets=s{,}',       'serve-static|serve-assets',
        'rewrite',                  'cgit-sharedir=s',
        'server|s=s',               @instance_optspec
    );

    if ( scalar @$listen ) {
        foreach my $listen (@$listen) {
            if ( $listen =~ $sockscheme_re ) {
                my $sock = path( $listen =~ s/$sockscheme_re//r );
                $sock->remove if $sock->exists;

                $listen = $sock;
                push @$sock, $sock;
            }
        }
    }
    else {
        push @$listen, ':5000';
    }

    if ( $$cliopts{sockchown} ) {
        my ( $uname, $group ) = split /\:/, $$cliopts{sockchown};
        $group //= $uname;

        if ( $uname == -1 ) {
            $sockchgrp = $$cliopts{sockchgrp} = $group;
        }

        dmsg $uname, $group, $$cliopts{sockchown};

        $sockchown =
          { uid => ( 0 + getpwnam($uname) ), gid => ( 0 + getgrnam($group) ) };
    }
    elsif ( $$cliopts{sockchgrp} ) {
        $sockchgrp = $$cliopts{sockchgrp};
    }

    $sockchmod = $$cliopts{sockchmod};

    foreach my $cgitrc (@$cgitrc) {
        my ( $rcfile, $mount, %opt ) = split /:/, $cgitrc, 1;
        $mount //= '/';

        $$instance{$cgitrc} = {
            %$cliopts,
            cgit   => "/usr/share/webapps/cgit/cgit.cgi",
            cgitrc => $cgitrc
        };

        if ( scalar keys %opt ) {
            GetOptionsFromArray( \%opt, $$instance{$cgitrc},
                @instance_optspec );
        }

        $$instance{$cgitrc}{app} =
          $self->new_instance( $$instance{$cgitrc} );

        $builder->mount( $mount, $$instance{$cgitrc}{app} );
    }

    $self->mount_middleware;
    $app = $self->to_app
}

method cmd : common ($cmd) {
    my %res = ( cmd => $cmd, out => [], err => [], exit => [] );

    $res{piperr} = run3( $cmd, \undef, @res{qw(out err)} );
    $res{exit}   = [ $?, $! ];

    foreach my $lines ( @res{qw(out err)} ) {
        @$lines = map { chomp $_; $_ } @$lines;
    }

    err $res{err} if $res{exit}->[0] > 0;

    dmsg \%res;
    \%res;
}

method mount_middleware {
    $builder->add_middleware_if(
        sub ($env) { !$env->{REMOTE_ADDR} },
        "Plack::Middleware::ReverseProxy"
    );

    if ( $ENV{PLACK_ENV} && ( $ENV{PLACK_ENV} eq 'development' ) ) {
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

        foreach my $file ( glob "$cgit_sharedir/cgit.{png,js,css,cgi}" ) {
            $file = path($file);
            warn "Could not open '$file'" && next unless $file->exists;
            $builder->mount( "/s/cgit/" . $file->basename,
                Plack::App::File->new( file => $file ) );
        }

        $builder->add_middleware(
            "Plack::Middleware::Static",
            path => sub { s!^/s/!! },
            root => $$cliopts{assets}
        );
    }
}

method new_instance ($opt) {
    my $app = Plack::App::WrapCGI->new(
        script  => $$opt{cgit},
        execute => 1
    )->to_app;

    Frame::App::cgit::Instance->wrap( $app, config => $$opt{cgitrc} );
}

method to_app {
    $builder->to_app;
}

method runnerargs {
    my @args = map { ( '--listen' => $_ ) } @$listen;
    push @args, '--server', $$cliopts{server};
    @args;
}

method socketperms {
    my $sockchown = $self->sockchown;
    foreach my $sock (@$sock) {
        my $modified = 0;

        $modified = chown( $$sockchown{uid}, $$sockchown{gid}, $sock )
          if $sockchown;

        err "$! ($?)" unless $modified;

        if ($sockchgrp) {
            my $chgrp_res =
              cgit->cmd( [ 'chgrp', $sockchgrp, "" . $sock->absolute ] );
        }

        if ($sockchmod) {
            try {
                $sockchmod = sprintf "%01d", $sockchmod
                  if ( $sockchmod =~ /[0-9]{3}/ );
                $sock->chmod($sockchmod);
            }
            catch ($e) {
                err $e;

                my $chgrp_res =
                  cgit->cmd( [ 'chmod', $sockchmod, "" . $sock->absolute ] );
            }
        }
    }
}

method run {
    require Plack::Runner;
    my $runner = Plack::Runner->new;

    $runner->parse_options( @ARGV, $self->runnerargs );
    $runner->run($app);

    $self->socketperms($sock);
    $self;
}

package main;

class main;
use lib 'lib';

use utf8;
use v5.40;

use IPC::Nosh::IO;

our $cgitsrv = cgit->new( argv => \@ARGV );

unless (caller) {
    $cgitsrv->run;
    err "$! ($?)" if $? != 0;
    exit $?;
}

$cgitsrv->app;
