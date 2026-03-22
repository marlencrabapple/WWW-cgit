#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package WWW::cgit::Crypt::Tripcode;

class WWW::cgit::Crypt::Tripcode;

use v5.40;

use MIME::Base64 qw'encode_base64 decode_base64';
use Encode       qw'encode decode';

use constant MAX_UNICODE => 1114111;

sub dot_to_dec : prototype($) ($dot) {
    unpack( 'N', pack( 'C4', split( /\./, $dot ) ) );    # wow, magic.
}

sub dec_to_dot : prototype($) ($dec) {
    join( '.', unpack( 'C4', pack( 'N', $dec ) ) );
}

sub mask_ip : prototype($$;$) ( $ip, $key, $algorithm ) {

    $ip = dot_to_dec($ip) if $ip =~ /\./;

    my ( $block, $stir ) = setup_masking( $key, $algorithm );
    my $mask = 0x80000000;

    for ( 1 .. 32 ) {
        my $bit = $ip & $mask ? "1" : "0";
        $block = $stir->($block);
        $ip ^= $mask if ( ord($block) & 0x80 );
        $block = $bit . $block;
        $mask >>= 1;
    }

    return sprintf "%08x", $ip;
}

sub unmask_ip : prototype($$;$) ( $id, $key, $algorithm ) {

    $id = hex($id);

    my ( $block, $stir ) = setup_masking( $key, $algorithm );
    my $mask = 0x80000000;

    for ( 1 .. 32 ) {
        $block = $stir->($block);
        $id ^= $mask if ( ord($block) & 0x80 );
        my $bit = $id & $mask ? "1" : "0";
        $block = $bit . $block;
        $mask >>= 1;
    }

    return dec_to_dot($id);
}

sub setup_masking : prototype($$) ( $key, $algorithm = 'md5' ) {

    my ( $block, $stir );

    if ( $algorithm eq "md5" ) {
        return ( md5($key), sub { md5(shift) } );
    }
    else {
        ...;

    }
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

sub hide_data : prototype($$$$;$) ( $data, $bytes, $key, $secret, $base64 ) {
    my $crypt =
      rc4( null_string($bytes), make_key( $key, $secret, 32 ) . $data );

    return encode_base64( $crypt, "" ) if $base64;
    return $crypt;
}

sub forbidden_unicode : prototype($;$) ( $dec, $hex ) {
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

sub clean_string : prototype($;$) ( $str, $cleanentities ) {

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

sub decode_string : prototype($;$$) ( $str, $charset, $noentities ) {
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
