use Object::Pad ':experimental(:all)';

package WWW::cgit::Instance;

class WWW::cgit::Instance : isa(Plack::Middleware) : does(WWW::cgit::Base);

use utf8;
use v5.40;

use Path::Tiny;
use List::Util qw'any none';
use IO::Handle::Common;
use Const::Fast;

field $cgit_pl  : param;
field $instance : param(app);
field $cgitrc;    #: param;
field $config : reader;
field $reload_cgitrc : param : reader //= $ENV{RELOAD_CGITRC} ? true : false;

ADJUST : params (:$cgitrc, %param) {

    # dmsg $self;
    $self->cgitrc($cgitrc);
    dmsg $self, $cgitrc, \%param;
};

method wrap : common ($app, @args) {
    my $self = $class->new( app => $app, @args );
    $self->to_app;
}

method cgitrc ( $path, %opt ) {
    $path = path($path) unless blessed($path) && $path->isa('Path::Tiny');
    $cgitrc //= $path;
    $config = $self->load_cgitrc unless $opt{noupdate};
}

method load_cgitrc {
    my $config = $self->parse_cgitrc($cgitrc);
    dmsg $config;
    $config

    # TODO: Make sure its within user's provisioned root
    #$$config{'scan-path'};
    # ...
}

method parse_cgitrc {
    const my $begin_comment => qr/^#/;
    foreach my $line (
        map  { chomp $_; $_ }
        grep { $_ !~ $begin_comment } $cgitrc->lines_utf8
      )
    {
        const my $sep => qr/=/;
        my ( $name, @strval ) = split( /$sep/, $line );
        next unless $name;
        my $field = ( $name =~ s/-/_/rg );
        push @strval, $self->{$field};

        # dmsg \@strval;

        next unless scalar @strval;

        const my @listkeys =>
          qw(clone-prefix clone-url clone-prefix project-list readme snapshots repo.clone-url);

        foreach my $strval (@strval) {
            next unless $strval;
            if ( any { $name eq $_ } @listkeys ) {
                const my $append => qr/^:(.+)$/;
                if ( $strval =~ s/$append/$1/ ) {
                    $$config{$name} //= [];
                    push $$config{$name}->@*, $strval
                      if none { $strval eq $_ } $$config{$name}->@*;
                }
                else {
                    const my $nbsp => qr/\s/;
                    my @val = split /$nbsp/, $strval;
                    $$config{$name} = \@val;
                }
            }
            else {
                $$config{$name} = $strval if $strval;
            }
        }
    }

    $config;
}

method call( $env, %opt ) {
    $self->load_cgitrc if $reload_cgitrc;
    $$env{CGIT_CONFIG} = $cgitrc->absolute;

    dmsg $env, \%opt;

    my $instance = $instance->($env);
    dmsg $instance;
    $instance;
}

