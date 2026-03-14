#!/usr/bin/env perl

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

our $patharg = sub ( $arg, %opt ) {
    $arg = path($arg)->assert(
        sub {
            $opt{assert} && $opt{assert} isa CODE ? $opt{assert}->(@_) : 1;
        }
    ) unless $arg isa Path::Tiny;

    if ( my $dest = $opt{dest} ) {
        if ( my $type = ref $dest ) {
            if ( $type eq 'ARRAY' ) {
                push @$dest, $arg;
            }
            elsif ( $type eq 'SCALAR' ) {
                $$dest = $arg;
            }
        }
        else {
            fatal '$dest must be a SCALAR, ARRAY, or CODE reference!';
            dmsg( $arg, $dest );
        }
    }
};

our %clidest = (
    modroot  => \$modroot,
    input    => [],
    outdir   => \$outdir,
    outfn    => \$outfn,
    locallib => \$locallib,
    verbose  => \$verbose,
    debug    => \$debug
);

GetOptions(
    \%clidest,
    'input|file|infile|infname|script=s{,}',
    => sub {
        $patharg->( shift, dest => \@input );
    },
    'outdir|fatpack-out=s',
    'outfn|outfname|out-filename|fnfmt|fmtfn|fmt-filename|fmt-outputfn=s',
    'modroot|module-root|module-dir=s',
    'locallib=s{,}',
    'verbose+',
    'debug',
    '<>' => sub ($in) { $patharg->( $in, dest => \@input ) }
);

my $cliopt_deref = {
    map {
        my $ref = ref $clidest{$_};
        ( $_ => ( $ref eq 'SCALAR' ? $clidest{$_}->$* : $clidest{$_} ) )
    } ( keys %clidest )
};

dmsg $cliopt_deref, \%clidest, \@input;

sub fatpack {
    $CWD = $modroot;
    run( [qw(carton install)] );

    $ENV{PERL5LIB} = "$locallib:$modroot/lib";

    $outdir->mkdir unless -d $outdir;

    foreach my $in ( map { $_->is_dir ? ( $_->children ) : $_ } @input ) {

        #fatpack($in->children) if $in->is_dir;
        my $fatline = [];
        my $fatstr  = "";
        my @cmd     = ( qw(fatpack pack), $in );

        binmode STDERR, ":encoding(UTF-8)";
        info( "Running " . join " ", @cmd );

        run( \@cmd, out => $fatline, autoflush => 1, autochomp => 1 );

        $fatstr = join "\n", @$fatline;

        my $fatout = sprintf(
            ( $outfn || '%s.fat' ),
            ( s/^(.+)(?:\.pl)?$/$1/rg =~ $in->basename )
        );

        if ( my ($ext) = $in->basename =~ /\.(pl)$/i ) {
            $fatout .= ".$ext";
        }

        path("$outdir/$fatout")->spew_utf8($fatstr);

        success("Written to: $fatout");
    }
}

fatpack()
