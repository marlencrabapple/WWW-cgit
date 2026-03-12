requires 'perl', 'v5.42';

requires 'Frame', '0.01.5', dist => 'CRABAPP/Frame-0.01.5-TRIAL.tar.gz';

requires 'Net::SSLeay';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';
requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'Plack::Middleware::Rewrite';
requires 'File::chdir';
requires 'IPC::Nosh',    dist => 'CRABAPP/IPC-Nosh-0.01-TRIAL.tar.gz';
requires 'App::md2html', dist => 'CRABAPP/IPC-Nosh-0.01-TRIAL.tar.gz';

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
};

on 'build' => sub {
    requires 'Module::Build::Tiny';
}
