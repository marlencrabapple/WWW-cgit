use Object::Pad;

package Frame::App::cgit::Model::User;
class Frame::App::cgit::Model::User :does(Frame::App::cgit::Model);

use utf8;
use v5.40;

# state $columns_base = Hash::Ordered->new(
#   id => {
#     type => 'INTEGER',
#     primary_key => 1,
#     autoincrement => 1,
#     not_null => 1
#   },
#   name => {},
#   email => {},
#   created => { type => 'Time::Moment', not_null => 1 },
#   updated => { type => 'Time::Moment', not_null => 1 },
#   lastaction => { type => 'Time::Moment', not_null => 1 },
#   lastlogin => { type => 'Time::Moment', not_null => 1 },
# );

apply Frame::Model;
use Frame::Model;


field $id :Type(INTEGER)
          :Primary
          :Autoinc
          :Notnull;
          
field $name;
field $pwhash;
field $created;

method init {

}