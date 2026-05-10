use Object::Pad ':experimental(:all)';

package WWW::cgit::Find;

class __PACKAGE__ : does(Frame::Controller);

use v5.40;

use File::Find;

