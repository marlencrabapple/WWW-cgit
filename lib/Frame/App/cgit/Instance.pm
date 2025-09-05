package Frame::App::cgit::Instance;
use parent 'Plack::Middleware';

use utf8;
use v5.40;

use Path::Tiny;
use Data::Printer;
use Plack::Util::Accessor qw(config);

sub call ( $self, $env, %args ) {
    $$env{CGIT_CONFIG} = path( $self->config )->absolute;
    my $res = $self->app->($env);
    $res;
}

