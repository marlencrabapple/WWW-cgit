use Object::Pad ':experimental(:all)';

package Frame::App::cgit::Instance;

class Frame::App::cgit::Instance : isa(Plack::Middleware);

use utf8;
use v5.40;

use Path::Tiny;

field $config : accessor { path( $self->{config} ) };

method call( $env, %opt ) {
    $$env{CGIT_CONFIG} = $config->absolute;
    $self->app->($env);
}

