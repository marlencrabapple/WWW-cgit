use Object::Pad ':experimental(:all)';

package Frame::App::cgit::Instance;

class Frame::App::cgit::Instance : isa(Plack::Middleware);

# use parent 'Plack::Middleware';

use utf8;
use v5.40;

use Path::Tiny;
use Data::Printer;

# use Plack::Util::Accessor qw(config);
use Syntax::Keyword::Dynamically;

use IPC::Nosh::IO;

field $config : accessor { $self->{config} };

method call( $env, %opt ) {
    $$env{CGIT_CONFIG} = path($config)->absolute;
    my $res = $self->app->($env);
    $res;
}

