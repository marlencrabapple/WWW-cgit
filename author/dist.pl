#!/usr/bin/env perl
use Object::Pad ':experimental(:all)';

package WWW::cgit::dist;

class WWW::cgit::dist;    #: isa(Dist::CRABAPP::Dist);

use utf8;
use v5.40;

use lib 'lib';

use Cwd 'abs_path';
use File::chdir;
use Path::Tiny;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case auto_abbrev);

use IPC::Nosh;
use IPC::Nosh::IO;

our $modroot  = path(abs_path);
our @input    = ( path("$modroot/script") );
our $outdir   = path('./bin');
our $outfn    = '%s';
our $locallib = path("$modroot/local");
our $verbose  = 1;
our $debug    = $verbose;

method build_distdir {
    `carton exec perl Build.PL`;
    `./Build`;
}

method build_distarch {
    my $hidedir = path('../')->tempdir;
    my $moved   = path('./bin')->move($hidedir);
    `minil dist --trial`;
    $moved->move($CWD);
}

my $self = __PACKAGE__->new;

#package WWW::cgit::dist::CLI;

#class WWW::cgit::dist::CLI;

$self->build_distdir;
$self->build_distarch;
