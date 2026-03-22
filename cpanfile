requires 'perl', 'v5.40';

requires 'Frame', '0.01.5', dist => 'CRABAPP/Frame-0.01.5-TRIAL.tar.gz';

requires 'Net::SSLeay';
requires 'Plack::App::WrapCGI';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';
requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'Plack::Middleware::Rewrite';
requires 'File::chdir';
requires 'IPC::Nosh',    dist => 'CRABAPP/IPC-Nosh-0.01-TRIAL.tar.gz';
requires 'App::md2html', dist => 'CRABAPP/App-md2html-0.01-TRIAL.tar.gz';
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
