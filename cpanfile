use v5.40;
use subs qw'requires recommends on feature suggests conflicts';

requires 'perl', 'v5.40';

requires 'Frame';

requires 'IO::Handle::Common', '0.01.1',
  dist => "CRABAPP/IPC-Handle-Common-0.01.1-TRIAL.tar.gz";

requires 'IO::Socket::SSL';

requires 'IPC::Nosh', '0.01.4', dist => "CRABAPP/IO-Nosh-0.01.4-TRIAL.tar.gz";

requires 'Net::SSLeay';
recommends 'Net::SSLeay::CA';

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
requires 'App::md2html';

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
