use Object::Pad ':experimental(:all)';

package Frame::App::cgit::Config;
role Frame::App::cgit::Config : does(Frame::App::cgit::Base);

use utf8;
use v5.40;

our $VERSION = "0.01";

use Cwd;
use TOML::Tiny 'from_toml';
use Path::Tiny;
use File::XDG;
use Const::Fast;
use Const::Fast::Exporter;

use Frame::App::cgit::Base;

const our $xdg         => File::XDG->new( name => 'Frame::App::cgit' );
const our @config_dirs => $xdg->config_dirs_list;  # Assuming there's some sort
                                                   # of heirarchal order to this
                                                   # list

BEGIN {
    our @EXPORT = qw(config);    # symbols to export on request
}

our $_config;
const our $CONFIG => $_config;

field $config : reader;

APPLY($mop) {
    my $class = $mop->name;
    $class->load_all_config;
    $class->import;
}

ADJUSTPARAMS($params) {
    $self->init
}

method init {
    __CLASS__->load_all_config( undef, $config );
}

my method load_config : common ($path) {

    if ( -r $path ) {
        my ( $config, $error ) = from_toml( $path->slurp_utf8 );
        dmsg( { config => $class::CONFIG, error => $error } );
        $_config = { %$CONFIG, $config->%* };
    }
}

method load_all_config :
  common ($dir_aref = [@config_dirs], $dest = $class::CONFIG, %opt) {
    foreach my $dir ( $dir_aref->@* ) {

        my $config_path = path("$dir/config.toml");
        dmsg( { dir => $dir, config_path => $config_path, class => $class } );
        load_config( $class, $config_path );
    }
}
