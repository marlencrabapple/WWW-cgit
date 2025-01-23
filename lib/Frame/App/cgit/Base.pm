use Object::Pad ':experimental(:all)';

package Frame::App::cgit::Base;
role Frame::App::cgit::Base;

use utf8;
use v5.40;

use Time::Moment;
use Time::Piece;
use Data::Dumper;
use Const::Fast;
use Syntax::Keyword::Dynamically;
use Exporter 'import';

BEGIN {
    our @EXPORT = qw(dmsg);
}

const our $DEBUG => $ENV{DEBUG} // 0;

eval { use Devel::StackTrace::WithLexicals } if $DEBUG;

use subs 'dmsg';

sub dmsg (@msgs) {
    $DEBUG || return '';

    my @caller = caller 0;

    my $out = "*** " . localtime->datetime . " - DEBUG MESSAGE ***\n\n";

    {
        dynamically $Data::Dumper::Pad    = "  ";
        dynamically $Data::Dumper::Indent = 1;

        $out .=
            scalar @msgs > 1 ? Dumper(@msgs)
          : ref $msgs[0]     ? Dumper(@msgs)
          :                    eval { my $s = $msgs[0] // 'undef'; "  $s\n" };

        $out .= "\n"
    }

    $out .=
      $ENV{DEBUG} && $ENV{DEBUG} == 2
      ? join "\n",
      map { ( my $line = $_ ) =~ s/^\t/    /; "  $line" } split /\R/,
      Devel::StackTrace::WithLexicals->new(
        indent      => 2,
        skip_frames => 1
      )->as_string
      : "at $caller[1]:$caller[2]";

    say STDERR "$out\n";
    $out;
}
