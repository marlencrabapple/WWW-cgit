requires 'perl', 'v5.42';

requires 'Frame', '0.01.5', dist => 'CRABAPP/Frame-0.01.5-TRIAL.tar.gz';

requires 'Net::Async::HTTP::Server';

requires 'Net::SSLeay';
requires 'Starlet';
requires 'Inline::C';
requires 'Inline::CPP';
requires 'Inline::Module';
requires 'FFI::Platypus';
requires 'Data::Printer';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';
requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'Plack::Middleware::Rewrite';
requires 'File::chdir';
requires 'Text::Markdown::Hoedown';
requires 'IPC::Nosh';
requires 'App::md2html';

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
    requires 'Minilla';
}
