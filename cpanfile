use v5.40;
use subs qw'requires recommends on';
requires 'perl', 'v5.40';

requires 'Const::Fast';

use Const::Fast;

const our $frame_ver => '0.1.6.0';
requires 'Frame',
  $frame_ver;    #, dist => 'CRABAPP/Frame-$frame_ver-TRIAL.tar.gz';

requires 'Net::SSLeay';
requires 'Plack::App::WrapCGI';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';
requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'Plack::Middleware::Rewrite';
requires 'File::chdir';

requires 'IPC::Nosh';

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
    requires 'Plack::Middleware::Static';
    requires 'Plack::Middleware::Debug';
    requires 'Plack::Middleware::ReverseProxy';
    recommends 'Plack::Middleware::REPL';
};

on 'build' => sub {
    requires 'Module::Build::Tiny';
}
