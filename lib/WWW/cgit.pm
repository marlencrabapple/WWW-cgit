use Object::Pad;

package WWW::cgit;

class WWW::cgit : does(Frame);

use utf8;
use v5.40;

our $VERSION = "0.01";

method startup {
    my $r      = $self->routes;
    my $config = $self->config;

    my $section = $r->under(
        '/:section',
        sub {
            $r->get( '/',             'section#repo_list' );
            $r->get( '/:landing_uri', 'section#render_landing' );
        }
    );

    my $repo = $section->under(
        '/:repo',
        sub ($r) {
            $r->get( '/',       'repo#readme_landing' );
            $r->get( '/log',    'repo#commit_log_paged' );
            $r->get( '/issues', 'issue#index' );
        }
    );

    $r->get( '/repo/new', 'repo#add_repo_form' );
    $r->post( '/repo/new', 'repo#add_repo' );

    $r->get( '/:repo/edit', 'repo#update_repo_form' );
    $r->post( '/:repo/edit', 'repo#update_repo' );

    $r->get( '/:repo/render/:file', 'repo#render_file' );

    $r->get( '/:user',    'user#view_user_profile' );
    $r->get( '/user/new', 'user#new_user_form' );
    $r->post( '/user/new', 'user#add_user' );
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

