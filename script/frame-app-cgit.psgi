use utf8;
use v5.40;

use lib 'lib';

use Path::Tiny;
use Plack::Builder;
use Plack::App::WrapCGI;
use Plack::Middleware::Static;

use Object::Pad;
use Frame::App::cgit;
use Frame::App::cgit::config;

our %cgimap = ( "frame-app" => '/' );

our $builder = Plack::Builder->new;

$builder->add_middleware_if(sub ($env) { !$env->{REMOTE_ADDR} }
  , "Plack::Middleware::ReverseProxy");

if ($ENV{PLACK_ENV} eq 'development') {
  $builder->add_middleware('Debug');
  $builder->add_middleware('StackTrace')
}

$builder->add_middleware("Plack::Middleware::Static"
                , path =>  sub { s!^/s/!! }
                , root => "/usr/share/webapps/cgit/");

foreach my ($section, $path) (%cgimap) {
  my $instance = Plack::App::WrapCGI->new(
    script => "/usr/share/webapps/cgit/cgit.cgi",
    execute => 1
  )->to_app;

  $instance = Frame::App::cgit::config
    ->wrap( $instance, config => $ENV{uc($section). "_CGITRC"}
                               // "./etc/${section}-cgitrc" );

  $builder->mount($path => $instance)
}

our $class = class :does(Frame) {
  use utf8;
  use v5.40;

  use lib 'lib';
  
  use Encode qw(encode decode);
  use Path::Tiny;
  use Data::Dumper;
  use Text::Markdown::Hoedown;

  our $kareha = CGI::Emulate::PSGI->handler(CGI::Compile->compile(
		"./kareha.pl", "kareha"));

  method startup {
    my $r = $self->routes;
    my $config = $self->config;

    $r->get('/:section/:repo/kareha', sub ($c) {

    });

    $r->get('/md2html', sub ($c) {
      my $htmlstr = __PACKAGE__->md2html($c->req->parameters->{mdfile});
      $c->render($htmlstr)
    });
  }

  method md2html :common ($mdin, %args) {
    my ($mdstr, $mdfile, $mdfh);

    if (-e $mdin) {
      $mdfile = path($mdin);
      $mdstr = $mdfile->slurp_utf8
    }
    else {
      $mdstr = $mdin
    }

    my $htmlout = markdown(encode('UTF-8', $mdstr)
      , html_options => HOEDOWN_HTML_HARD_WRAP|HOEDOWN_HTML_ESCAPE,
        extensions => HOEDOWN_EXT_TABLES|HOEDOWN_EXT_FENCED_CODE
          |HOEDOWN_EXT_FOOTNOTES|HOEDOWN_EXT_AUTOLINK|HOEDOWN_EXT_STRIKETHROUGH
          |HOEDOWN_EXT_UNDERLINE|HOEDOWN_EXT_HIGHLIGHT|HOEDOWN_EXT_QUOTE
          |HOEDOWN_EXT_SUPERSCRIPT|HOEDOWN_EXT_MATH);

    $args{html_out}
      ? path($args{html_out})->spew_utf8($htmlout)
      : "$htmlout"
  }

};

$builder->mount('/', $class->new->to_psgi);
$builder->to_app
