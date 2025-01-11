requires 'perl', 'v5.40';

requires 'Frame', '0.01.2',
  dist => 'CRABAPP/Frame-0.01.2-TRIAL.tar.gz';

requires 'Data::Printer';
requires 'CGI::Compile';
requires 'CGI::Emulate::PSGI';
requires 'Plack::Builder';
requires 'Plack::Middleware::Auth::Basic';
requires 'File::chdir';
requires 'Text::Markdown::Hoedown';

on 'test' => sub {
  requires 'Test::More', '0.98';
};

on 'develop' => sub {
  requires 'Perl::Tidy', '20220613';
  requires 'Perl::Critic', '1.140';
  requires 'Perl::Critic::Community';
  requires 'Plack::Middleware::Static';
  requires 'Plack::Middleware::Debug';
  requires 'Plack::Middleware::ReverseProxy';
};

on 'build' => sub {
  requires 'Minilla'
}
