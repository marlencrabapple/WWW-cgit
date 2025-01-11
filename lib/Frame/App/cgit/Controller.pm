use Object::Pad;

package Frame::App::cgit::Controller;
role Frame::App::cgit::Controller :does(Frame::Controller);

use utf8;
use v5.40;

$Frame::Controller::template_vars->@{qw()} = ('hikki', '/s/');

