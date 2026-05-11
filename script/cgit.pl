#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package cgitpl;

class cgitpl;

use utf8;
use v5.40;

use lib 'lib';

use List::Util          qw(any none all mesh);
use Const::Fast         qw( const );
use Path::Tiny          qw( path );
use Getopt::Long        qw(GetOptionsFromArray :config no_ignore_case);
use Plack::Runner       ();
use Plack::Builder      ();
use Plack::App::WrapCGI ();
use Cwd                 qw( abs_path getcwd );
use File::chdir;
use Syntax::Keyword::Dynamically;

use IPC::Nosh;
use IPC::Nosh::Common;

use WWW::cgit;
use WWW::cgit::Instance;

const our $sockscheme_re => qr'^unix://';

field $argv : param;
field $app;
field $instance = {};
field $builder { Plack::Builder->new }
field $execdir       : accessor //= path(abs_path);
field $cgit_sharedir : accessor = "/usr/share/webapps/cgit";
field $cgitrc        : reader   = [];
field $config_file;
field $sockchown : reader;
field $sockchgrp : reader;
field $sockchmod : reader;
field $listen    : reader = [];
field $sock;

field $plenvroot : reader { path("$execdir/.plenv") }

field $cliopts : param(dest) : reader {
    {
        mount           => '/',
        cgitrc          => $cgitrc,
        execdir         => $execdir,
        'cgit-sharedir' => $cgit_sharedir,
        assets          => ["$execdir/www"],
        listen          => $listen,
        'serve-static'  => $ENV{PLACK_ENV}
          && $ENV{PLACK_ENV} eq 'development' ? 1 : 0,
        plenv    => "",
        plenvver => ''
    }
};

ADJUSTPARAMS($params) {
    const my @instance_optspec => (
        'basicauth|auth|http-basic-auth=s',
        'config=s',
        'execdir' => sub ( $getopt, $val ) { $self->execdir( path($val) ) },
        'ssl-certfile|certfile|sslcert|ssl-cert-file=s',
        'ssl-keyfile|keyfile|sslkey|ssl-key-file=s',
        'cgit|cgi|script=s',
    );

    GetOptionsFromArray(
        $argv,          $cliopts,
        'cgitrc=s{,}',  'verbose+',
        'debug+',       'verion',
        'help|usage|?', 'mount=s',
        'listen=s{1,}',
        'sockchown|socket-chown|sockuser|sock-user|sockown|sock-owner=s',
        'sockchgrp|socket-chgrp|sockgrp|sock-group|sockgroup=s',
        'sockchmod|socket-chmod|sockmode|sock-mode=s',

        # TODO: fatal ver of the above
        # 'sockowner|sock-owner=s', 'sockgroup|sock-group|sockgrp=s',

        'static|assets=s{,}', 'serve-static|serve-assets',
        'rewrite',
        'cgit-sharedir=s' =>
          sub ( $getopt, $val ) { $self->cgit_sharedir( path($val) ) },
        'plenv',      'plenvver|plenv-version=s',
        'server|s=s', @instance_optspec
    );

    dmsg $cliopts, $argv;

    if ( $$cliopts{plenv} ) {
        $self->plenvinit;
    }

    if ( scalar @$listen ) {
        foreach my $listen (@$listen) {
            if ( $listen =~ $sockscheme_re ) {
                my $sock   = path( $listen =~ s/$sockscheme_re//r );
                my $rundir = $sock->parent;
                dmsg( $rundir, $sock, $listen );
                $rundir->mkdir unless $rundir->exists;
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

        if ( $uname eq '-1' ) {
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
            GetOptionsFromArray( [%opt], $$instance{$cgitrc},
                @instance_optspec );
        }

        $$instance{$cgitrc}{app} =
          $self->new_instance( $$instance{$cgitrc} );

        $builder->mount( $mount, $$instance{$cgitrc}{app} );
    }

    $builder->mount( '/test', WWW::cgit->new->to_psgi );

    $self->mount_middleware;
    $app = $self->to_app
}

method plenvinit {
    my ($shell) = $ENV{SHELL} =~ s/^(?:.*\/)?([^\/]+)$/$1/rg;

    my @rcpath =
      map { path("$execdir/$_") }
      ( '.profile', ( $shell ? '.' . $shell . 'rc' : () ) );

    my $plenvpath = "$plenvroot/bin:$ENV{PATH}";

    $ENV{PLENV_ROOT} = $plenvroot;

    my $plenvinit = q'eval "$(plenv init -)"';

    unless ( path('.plenvsetup')->is_file ) {
        foreach my $path (@rcpath) {
            $path->append_utf8(qq'export PATH="$plenvpath"\n');
            $path->append_utf8("$plenvinit\n");
        }

        $ENV{PATH} = $plenvpath;
    }

    foreach my $cmd (qw'install local shell') {
        info "Building and installing perl with plenv to '$plenvroot'. "
          . "This may take a while...";

        my $run = cgitpl->cmd( [ 'plenv', $cmd, $$cliopts{plenvver} ] );

        dmsg $run;
    }
}

method plenvinstall :
  common ($version = (WWW::cgit->plenvinstall_list)[0], %opt) {

    run( [ qw(plenv install), $version, ] );
}

method plenvinstall_list : common (%opt) {

    # TODO: Look up these version formats: 5.5.670, 5.003_13
    const my $perlver_re => qr/^
        5
        \.([0-9]+?)                 # major (even is stable)
        (?:\.([0-9]+?)              # minor (optional, defaults to latest)
        (?:-(RC|TRIAL[0-9]+?))?)?   # ...
    $/xx;

    $opt{sortdir} //= 'desc';
    my $filter = $opt{filter} //= 'stable';

    my @avail = ();

    run(
        [qw(plenv install -l)],
        autochomp => 1,
        out       => sub ($line) {

            my ( $major, $minor, $extra ) = $line =~ $perlver_re;

            return undef unless $major && $minor;

            return undef
              if $filter eq 'stable' && any { $_ } ( ( $minor % 2 ), $extra );

            push @avail, $line;
        }
    );

    $opt{sortdir} eq 'desc'    ? @avail
      : $opt{sortdir} eq 'arc' ? reverse @avail
      : error
      "Invalid sortdir '$opt{sortdir}'. Must be 'asc', 'desc', or undef.";
}

# method perlver_latest_stable

method cmd : common ($cmd, %opt) {

    my $run = run(
        $cmd,
        autochomp => 1,
        autoflush => 1,
        on        => { line => sub { say shift } },
    );

    error "'"
      . ( join ' ', @$cmd ) . "' "
      . "exited with "
      . $run->status . ": "
      . ( join "\n", $run->err->@* )
      if $run->status != 0;

    dmsg $run;
    $run;
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

    if ( $$cliopts{'serve-static'} ) {
        use Plack::App::File;

        $builder->add_middleware(
            "Plack::Middleware::Static",
            path         => sub { s!^/s/!! },
            root         => $$cliopts{assets},
            pass_through => 1,
        );

        my @cgitstatic = glob "$cgit_sharedir/cgit.{png,js,css}";
        dmsg \@cgitstatic;

        foreach my $file ( map { path($_) } @cgitstatic ) {
            unless ( $file->exists ) {
                error "Could not open '$file'";
                next;
            }

            $builder->mount( "/s/cgit/" . $file->basename,
                Plack::App::File->new( file => $file )->to_app );
        }

    }
}

method new_instance ($opt) {
    if ( my $execdir = $$opt{execdir} // $$cliopts{execdir} ) {
        dynamically $CWD = $execdir;
    }

    my $app = Plack::App::WrapCGI->new(
        script  => $$opt{cgit},
        execute => 1
    )->to_app;

    WWW::cgit::Instance->wrap( $app, config_file => $$opt{cgitrc} );
}

method to_app {
    dmsg $builder;
    $builder->to_app;
}

method runnerargs {
    my @args = map { ( '--listen' => $_ ) } @$listen;

    push @args, '--server', $$cliopts{server};

    if (
        all { $_->is_file }
        map { path($_) } grep { $_ } ( @$cliopts{qw'ssl-certfile ssl-keyfile'} )
      )
    {
        push @args, qw(--ssl --ssl-server --ssl-key-file),
          $$cliopts{'ssl-keyfile'}, '--ssl-cert-file',
          $$cliopts{'ssl-certfile'};
    }
    @args;
}

method chmod : common ($mode, $path) {
    try {
        $mode = sprintf "%01d", $mode
          if ( $mode =~ /[0-9]{3}/ );
        $path->chmod($mode);
    }
    catch ($e) {
        error $e;
        cgit->cmd( [ 'chmod', $mode, "" . $path->absolute ] );
    }
}

method socketperms {
    my $sockchown = $self->sockchown;
    foreach my $sock (@$sock) {
        my $modified = 0;

        $modified = chown( $$sockchown{uid}, $$sockchown{gid}, $sock )
          if $sockchown;

        error "$! ($?)" unless $modified;

        if ($sockchgrp) {
            my $chgrp_res =
              cgit->cmd( [ 'chgrp', $sockchgrp, "" . $sock->absolute ] );
        }

        if ($sockchmod) {

        }
    }
}

method start {
    require Plack::Runner;
    my $runner = Plack::Runner->new;

    $runner->parse_options( @ARGV, $self->runnerargs );
    $runner->run($app);

    $self->socketperms($sock);
    $self;
}

package cgitpl::cli;

class cgitpl::cli;
use lib 'lib';

use utf8;
use v5.40;

use IPC::Nosh::Common;

our $cgitsrv = cgitpl->new( argv => \@ARGV );

unless (caller) {
    $cgitsrv->start;
    error "$! ($?)" if $? != 0;
    exit $?;
}

$cgitsrv->app;

__END__

=encoding utf-8

=head1 NAME

cgit.pl: a cgit launcher, server/instance mangager and Plack/PSGI interface

=head1 SYNOPSIS

    cgit.pl \
     -s Frame::Server
     -sslcert=path/to/cert.pem \
     -sslkey=path/to/key.pem \
     -user=cgit:http
     -listen ':443' ':80'


=head1 DESCRIPTION

WWW::cgit is ...

=head1 LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=cut

