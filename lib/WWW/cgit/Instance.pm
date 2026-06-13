use Object::Pad ':experimental(:all)';

package WWW::cgit::Instance;

class WWW::cgit::Instance : isa(Plack::Middleware);

use utf8;
use v5.40;

use Path::Tiny;
use List::Util 'any';
use IO::Handle::Common;

field $app { $self->{app} };
field $config_file : accessor { path( $self->{config_file} ) };
field $config : reader;

method load_config {

    $self->parse_config($config_file);
    dmsg $self

    # Make sure its within user's provisioned root
    #$$config{'scan-path'};
    # ...;
}

method parse_config {
    foreach my $line ( grep { !/^#/ } $config_file->lines_utf8 ) {
        chomp $line;

        my ( $name, $strval ) = split /=/, $line;

        next unless $name && $strval;

        my @listkeys =
          qw(clone-prefix clone-url clone-prefix project-list readme snapshots repo.clone-url);

        if ( any { $name eq $_ } @listkeys ) {
            if ( $strval =~ s/^:(.+)$/$1/ ) {
                $$config{$name} //= [];
                push $$config{$name}->@*, $strval;
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
}

method call( $env, %opt ) {

    $self->load_config;
    $$env{CGIT_CONFIG} = $config_file->absolute;

    $self->app->($env);
}

