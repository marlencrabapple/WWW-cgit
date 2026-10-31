use Object::Pad ':experimental(:all)';

package WWW::cgit::Instance::WrapCGI;

class WWW::cgit::Instance::WrapCGI : isa(Plack::App::WrapCGI);

use utf8;
use v5.40;

use Path::Tiny;
use POSIX ':sys_wait_h';
use CGI::Compile;
use CGI::Emulate::PSGI;
use IO::Handle::Common;
use Capture::Tiny qw':all';
use Syntax::Keyword::Dynamically;
use IPC::Nosh;

field $script  : param;
field $execute : param = undef;
field $psgi    : accessor(app);

method slurp_fh($fh) {
    IO::Handle::Common::Handle->new( fh => $fh );
}

method prepare_app (%opt) {
    my $script = path( $self->script // fatal "'script' is not set" )->absolute;

    if ( $self->execute ) {
        my $app = sub ($env) {
            run($self->script, in => $env->{'psgi.input'}, out => )
        };

        $self->app = $app;
    }
}

method call ($env) {
    $psgi->($env);
}
