use Object::Pad;

package Frame::App::cgit::Db;
role Frame::App::cgit::Db :does(Frame::Db::SQLite);

use utf8;
use v5.40;

field $app;
field $source :param = 'sqlite.sqlite3';
field $user :param = "";
field $auth :param = "";
field $attr :param = "";

method init_db ($config) {
  $app = $self->app
}

method table_exists :common {

}

method dbh :required;