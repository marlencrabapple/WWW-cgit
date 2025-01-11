use Object::Pad qw(:experimental(:all));

package Frame::App::cgit::Model;
role Frame::App::cgit::Model :does(Frame::Model);

use utf8;
use v5.40;

APPLY ($mop) {
  my $class = $mop->name;

  foreach my $colattr (qw(Type Primary Foreign Autoinc Notnull)) {
    Object::Pad::MOP::FieldAttr->register(
      $colattr,
      permit_hintkey => "$class/dbmodel",
      apply => sub { $class->$colattr }
    )
  }

  $^H{"$class/dbmodel"} = 1 
}

method import :common :override {
  $^H{"$class/dbmodel"} = 1 
}