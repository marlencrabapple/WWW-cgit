use utf8;
use v5.40;

use lib 'lib';

use Path::Tiny;
use Plack::Builder;
use Plack::App::WrapCGI;
use Plack::Middleware::Static;
use Frame::App::cgit::Config;
use Object::Pad;
use Frame::App::cgit;
use Frame::App::cgit::Instance;

our %cgimap = ( "frameapp" => '/' );

our $builder = Plack::Builder->new;

$builder->add_middleware_if( sub ($env) { !$env->{REMOTE_ADDR} },
    "Plack::Middleware::ReverseProxy" );

if ( $ENV{PLACK_ENV} eq 'development' ) {
    $builder->add_middleware('Debug');
    $builder->add_middleware('StackTrace');
}

$builder->add_middleware(
    "Plack::Middleware::Static",
    path => sub { s!^/s/!! },
    root => "/usr/share/webapps/cgit/"
);

foreach my ( $section, $path ) (%cgimap) {
    my $instance = Plack::App::WrapCGI->new(
        script  => "/usr/share/webapps/cgit/cgit.cgi",
        execute => 1
    )->to_app;

    $instance = Frame::App::cgit::config->wrap( $instance,
        config => $ENV{ uc($section) . "_CGITRC" }
          // uc "./etc/${section}-cgitrc" );

    $builder->mount( $path => $instance );
}

our $class = class : does(Frame) {
    use utf8;
    use v5.40;

    use lib 'lib';

    use Encode qw(encode decode);

    #use Data::Dumper;
    use Text::Markdown::Hoedown;
    use CGI::Emulate::PSGI;
    use CGI::Compile;

    #use Plack::App::WrapCGI;

    our $kareha = CGI::Emulate::PSGI->handler(
        CGI::Compile->compile( "./kareha.pl", "kareha" )
    );

    our $admin = CGI::Emulate::PSGI->handler(
        CGI::Compile->compile( "./admin.pl", "admin" )
    );

    method startup {
        my $r      = $self->routes;
        my $config = $self->config;

        $r->get(
            '/:section/:repo/kareha',
            sub ($c) {

            }
        );

        #$r->get('/md2html', sub ($c) {
        #  my $htmlstr = __PACKAGE__->md2html($c->req->parameters->{mdfile});
        #  $c->render($htmlstr)
        #});
    }
};

$builder->mount( '/', $class->new->to_psgi );
$builder->to_app
