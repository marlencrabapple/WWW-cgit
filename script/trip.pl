#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package WWW::cgit::Crypt::Tripcode;

class WWW::cgit::Crypt::Tripcode;

use utf8;
use v5.40;

use Path::Tiny;
use TOML::Tiny;
use MIME::Base64 qw'encode_base64 decode_base64';
use Encode       qw'encode decode';
use IO::Handle::Common;
use Digest::MD5 'md5';

use constant MAX_UNICODE => 1114111;
use constant CHARSET     => 'UTF-8';

our $config =
  from_toml( path( $ENV{WWWCGIT_CONFIG} // 'config.toml' )->slurp_utf8 );

our %charmap = (
    a => [4],
    b => [8],
    c => [qw'('],
    d => [],
    e => [3],
    f => [qw'㏗'],     # Maybe use this for p and h to reduce collision size
    g => [qw'6 9'],
    h => [],
    i => [1],
    j => [],
    k => [],
    l => [],
    m => [],
    n => [],
    o => [0],
    p => [],
    q => [],
    r => [],
    s => [5],
    t => [qw'+ 7'],
    u => [],
    v => [],
    w => [],
    x => [],
    y => [],
    z => [],
);

sub process_tripcode : prototype($;$$$$) (
    $name,
    $tripkey        = $config->{id}{secret},
    $secret         = $config->{id}{secret},
    $charset        = CHARSET,
    $nonamedecoding = 1
  )
{
    $tripkey = "!" unless ($tripkey);

    if ( $name =~ /^(.*?)((?<!&)#|\Q$tripkey\E)(.*)$/ ) {
        my ( $namepart, $marker, $trippart ) = ( $1, $2, $3 );
        my $trip;

        $namepart = decode_string( $namepart, $charset ) unless $nonamedecoding;
        $namepart = clean_string($namepart);

        if (    $secret
            and $trippart =~ s/(?:\Q$marker\E)(?<!&#)(?:\Q$marker\E)*(.*)$//
          )    # do we want secure trips, and is there one?
        {
            my $str    = $1;
            my $maxlen = 255 - length($secret);
            $str = substr $str, 0, $maxlen if ( length($str) > $maxlen );

#			$trip=$tripkey.$tripkey.encode_base64(rc4(null_string(6),"t".$str.$secret),"");
            $trip =
              $tripkey . $tripkey . hide_data( $1, 6, "trip", $secret, 1 );
            return ( $namepart, $trip )
              unless ($trippart)
              ;    # return directly if there's no normal tripcode
        }

        $trippart = decode_string( $trippart, $charset );
        $trippart = encode( "Shift_JIS", $trippart, 0x0200 );

        $trippart = clean_string($trippart);
        my $salt = substr $trippart . "H..", 1, 2;
        $salt =~ s/[^\.-z]/./g;
        $salt =~ tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/;
        $trip = $tripkey . ( substr crypt( $trippart, $salt ), -10 ) . $trip;

        return ( $namepart, $trip );
    }

    return clean_string($name) if $nonamedecoding;
    return ( clean_string( decode_string( $name, $charset ) ), "" );
}

sub rc4 : prototype($$;$) ( $message, $key, $skip = undef ) {
    my @s       = 0 .. 255;
    my @k       = unpack 'C*', $key;
    my @message = unpack 'C*', $message;
    my ( $x, $y );
    $skip = 256 unless ( defined $skip );

    $y = 0;
    for my $x ( 0 .. 255 ) {
        $y = ( $y + $s[$x] + $k[ $x % @k ] ) % 256;
        @s[ $x, $y ] = @s[ $y, $x ];
    }

    $x = 0;
    $y = 0;
    for ( 1 .. $skip ) {
        $x = ( $x + 1 ) % 256;
        $y = ( $y + $s[$x] ) % 256;
        @s[ $x, $y ] = @s[ $y, $x ];
    }

    for (@message) {
        $x = ( $x + 1 ) % 256;
        $y = ( $y + $s[$x] ) % 256;
        @s[ $x, $y ] = @s[ $y, $x ];
        $_ ^= $s[ ( $s[$x] + $s[$y] ) % 256 ];
    }

    return pack 'C*', @message;
}

sub make_random_string : prototype($) ($num) {
    my $chars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    my $str;

    $str .= substr $chars, rand length $chars, 1 for ( 1 .. $num );

    $str;
}

sub null_string : prototype($) ($len) { "\0" x ($len) }

sub make_key : prototype($$$) ( $key, $secret, $length ) {
    rc4( null_string($length), $key . $secret );
}

sub hide_data : prototype($$$$;$) ( $data, $bytes, $key, $secret, $base64 = 1 )
{
    my $crypt =
      rc4( null_string($bytes), make_key( $key, $secret, 32 ) . $data );

    return encode_base64( $crypt, "" ) if $base64;
    return $crypt;
}

sub forbidden_unicode : prototype($;$) ( $dec, $hex = undef ) {
    return 1 if length($dec) > 7 or length($hex) > 7;    # too long numbers
    my $ord = ( $dec or hex $hex );

    return 1 if $ord > MAX_UNICODE;                      # outside unicode range
    return 1 if $ord < 32;                               # control chars
    return 1 if $ord >= 0x7f   and $ord <= 0x84;         # control chars
    return 1 if $ord >= 0xd800 and $ord <= 0xdfff;       # surrogate code points
    return 1 if $ord >= 0x202a and $ord <= 0x202e;       # text direction
    return 1 if $ord >= 0xfdd0 and $ord <= 0xfdef;       # non-characters
    return 1 if $ord % 0x10000 >= 0xfffe;                # non-characters
    return 0;
}

sub clean_string : prototype($;$) ( $str, $cleanentities = undef ) {

    if ($cleanentities) { $str =~ s/&/&amp;/g }          # clean up &
    else {
        $str =~ s/&(#([0-9]+);|#x([0-9a-fA-F]+);|)/
			if($1 eq "") { '&amp;' } # change simple ampersands
			elsif(forbidden_unicode($2,$3))  { "" } # strip forbidden unicode chars
			else { "&$1" } # and leave the rest as-is.
		/ge    # clean up &, excluding numerical entities
    }

    $str =~ s/\</&lt;/g;     # clean up brackets for HTML tags
    $str =~ s/\>/&gt;/g;
    $str =~ s/"/&quot;/g;    # clean up quotes for HTML attributes
    $str =~ s/'/&#39;/g;
    $str =~ s/,/&#44;/g;     # clean up commas for some reason I forgot

    $str =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g;    # remove control chars

    return $str;
}

sub decode_string : prototype($;$$)
  ( $str, $charset = CHARSET, $noentities = undef ) {
    my $use_unicode = $charset;

    $str = decode( $charset, $str ) if $use_unicode;

    $str =~ s{(&#([0-9]*)([;&])|&#([x&])([0-9a-f]*)([;&]))}{
		my $ord=($2 or hex $5);
		if($3 eq '&' or $4 eq '&' or $5 eq '&') { $1 } # nested entities, leave as-is.
		elsif(forbidden_unicode($2,$5))  { "" } # strip forbidden unicode chars
		elsif($ord==35 or $ord==38) { $1 } # don't convert & or #
		elsif($use_unicode) { chr $ord } # if we have unicode support, convert all entities
		elsif($ord<128) { chr $ord } # otherwise just convert ASCII-range entities
		else { $1 } # and leave the rest as-is.
	}gei unless $noentities;

    $str =~ s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g;    # remove control chars

    return $str;
}

# our ( $name, $trip ) = map { ( split /##?/, $_ ) } @ARGV;

say process_tripcode(
    $_,
    $config->{id}{trip_key},
    $config->{id}{secret},
    CHARSET, 1
) for @ARGV;
