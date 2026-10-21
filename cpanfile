use v5.40;
use subs qw'requires recommends on feature suggests conflicts';

requires 'perl', 'v5.44';

requires 'Const::Fast';
use Const::Fast;

sub distname ($pkgname) {
    const my $pkg2dist => qr/::/;
    ( $pkgname =~ s/$pkg2dist/-/rg );
}

const our %pinned => (
    CRABAPP => {
        'Path::Try'          => '0.01_03',
        'IO::Handle::Common' => '0.01_3',
        'IPC::Nosh'          => '0.01_04',
        'Frame' => '0.01_7'
    }
);

foreach my ( $author, $modules ) (%pinned) {
    foreach my ( $name, $ver ) (%$modules) {
        requires $name, $ver,
          dist => "$author/" . distname($name) . "-$ver-TRIAL.tar.gz";
    }
}

requires 'IO::Socket::SSL';
requires 'Net::SSLeay';

requires 'Plack::App::WrapCGI';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';

requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'Plack::Middleware::Rewrite';
requires 'Plack::Middleware::ReverseProxy';
requires 'Plack::Middleware::Static';

requires 'File::chdir';
requires 'TOML::Tiny';
requires 'JSON::MaybeXS';

requires 'DBIx::Connector';
requires 'SQL::Abstract';
requires 'DBD::SQLite';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Perl::Tidy',   '20220613';
    requires 'Perl::Critic', '1.140';
    requires 'Perl::Critic::Community';
    requires 'Plack::Middleware::Debug';

    # requires 'Devel::Trace';
    requires 'Plack::Middleware::StackTrace';
    recommends 'Plack::Middleware::REPL';
};

on 'build' => sub {
    requires 'Module::Build::Tiny';
};

feature 'markdown',
  "Provide markdown to HTML functionality for cgit's about-filter" => sub {
    requires 'App::md2html';
  };

feature 'http', 'Serve content where SSL/TLS is unavailable' => sub {
    requires 'Starlet';
};
