use Object::Pad;

package WWW::cgit;

class WWW::cgit : does(Frame) : does(Frame::Controller);

use utf8;
use v5.40;

use Text::Xslate;
use JSON::MaybeXS;

our $VERSION = "0.01";

method startup {
    my $r      = $self->routes;
    my $config = $self->config;

    $r->get(
        '/',
        sub ($c) {
            Frame::Controller->template('new-identity.html.tx');

            #encode_json( { Hello => 'world!' } );
        }
    );
}

__END__

=encoding utf-8

=head1 NAME

WWW::cgit - A Plack/PSGI wrapper around cgit with a few additional features

=head1 SYNOPSIS

    use WWW::cgit;

=head1 DESCRIPTION

WWW::cgit is ...

=head1 LICENSE

Copyright (C) Ian P Bradley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ian P Bradley E<lt>ian.bradley@studiocrabapple.comE<gt>

=cut

