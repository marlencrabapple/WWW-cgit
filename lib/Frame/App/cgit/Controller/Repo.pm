use Object::Pad;

package Frame::App::cgit::Controller::Repo;
role Frame::App::cgit::Controller::Repo :does(Frame::Controller);

use utf8;
use v5.40;

use Carp;
use Path::Tiny;
use File::chdir;
use Data::Dumper;
use File::Basename;
use Text::Markdown::Hoedown;
use Encode qw(encode decode);

method render_file ($section, $repo, $path) {
  my ($fn, $pathto, $ext) = fileparse($path, qw(md));
  my $html = md2html($path);
  
  $self->render('repo/render-file.html.tx', {
    repo => $repo,
    path => $path,
    filename => $fn,     
    rendered => mark_raw($html),             
  })              
}

method readme_landing {
  say Dumper($self)
}

method md2html :common ($mdin, %args) {
  my ($mdstr, $mdfile, $mdfh);

  if (-e $mdin) {
    $mdfile = path($mdin);
    $mdstr = $mdfile->slurp_utf8
  }
  elsif (ref $mdin eq 'GLOB') {
    my @mdlines = <$mdin>;
    $mdstr = join ',', @mdlines
  }
  else {
    $mdstr = $mdin
  }

  my $htmlout = markdown(encode('UTF-8', $mdstr)
    , html_options => HOEDOWN_HTML_HARD_WRAP|HOEDOWN_HTML_ESCAPE,
      extensions => HOEDOWN_EXT_TABLES|HOEDOWN_EXT_FENCED_CODE
        |HOEDOWN_EXT_FOOTNOTES|HOEDOWN_EXT_AUTOLINK|HOEDOWN_EXT_STRIKETHROUGH
        |HOEDOWN_EXT_UNDERLINE|HOEDOWN_EXT_HIGHLIGHT|HOEDOWN_EXT_QUOTE
        |HOEDOWN_EXT_SUPERSCRIPT|HOEDOWN_EXT_MATH);

  $args{html_out}
    ? path($args{html_out})->spew_utf8($htmlout)
    : "$htmlout"
}

method create_pdf :common ($in, $out, %args) {
  ($in, $out) = map { $_ isa Path::Tiny ? $_ : path($_) } ($in, $out);

  $in = md2html($in) if $args{markdown} && $args{markdown} == 1;
  $in .= $args{append_to_html} if $args{append_to_html};

  my $wperr;
  my $ret = run3([ 'weasyprint', 
                 , $args{wp_args}->%*, '-'
                 , \$out ] , \$in, \$wperr);

  croak sprintf "%s (%s: %s)", $wperr, $?, $! unless $ret == 0;
  $out
}