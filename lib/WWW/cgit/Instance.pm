use Object::Pad ':experimental(:all)';

package WWW::cgit::Instance;

class WWW::cgit::Instance : isa(Plack::Middleware);

use utf8;
use v5.40;

use Path::Tiny;
use List::Util qw'any none';
use IO::Handle::Common;

field $app : param;
field $cgitrc;    #: param;
field $config : reader;
field $reload_cgitrc : param : reader //= $ENV{RELOAD_CGITRC} ? true : false;

# method BUILDARGS : common (%args) {
#     ( delete $args{env}, 1, %args )
# }

ADJUST : params (:$cgitrc) { $self->cgitrc($cgitrc) };

method wrap : common ($app, @args) {
    my $self = $class->new( app => $app, @args );
    $self->to_app;
}

method cgitrc ( $path, %opt ) {
    $cgitrc =
      blessed( $self->{cgitrc} )
      && $self->{cgitrc} isa 'Path::Tiny'
      ? $path->realpath
      : path( $self->{cgitrc} );

    $config = $self->load_cgitrc unless $opt{noupdate};
}

method load_cgitrc {
    my $config = $self->parse_cgitrc($cgitrc);
    dmsg $self, $config;
    $config

    # TODO: Make sure its within user's provisioned root
    #$$config{'scan-path'};
    # ...
}

method parse_cgitrc {
    foreach my $line ( map { chomp $_; $_ } grep { !/^#/ } $cgitrc->lines_utf8 )
    {
        my ( $name, $strval ) = split /=/, $line;

        next unless $name && $strval;

        my @listkeys =
          qw(clone-prefix clone-url clone-prefix project-list readme snapshots repo.clone-url);

        if ( any { $name eq $_ } @listkeys ) {
            if ( $strval =~ s/^:(.+)$/$1/ ) {
                $$config{$name} //= [];
                push $$config{$name}->@*, $strval
                  if none { $strval eq $_ } $$config{$name}->@*;
            }
            else {
                my @val = split /\s/, $strval;
                $$config{$name} = \@val;
            }
        }
        else {
            $$config{$name} = $strval;
        }
    }

    $config;
}

method call( $env, %opt ) {
    $self->load_cgitrc if $reload_cgitrc;
    $$env{CGIT_CONFIG} = $cgitrc->absolute;
    $self->app->($env);
}

