use Object::Pad ':experimental(:all)';

package WWW::cgit::Base;
role WWW::cgit::Base : does(Adjust::Params);

use utf8;
use v5.44;

use parent 'Exporter';
use vars qw'@EXPORT @EXPORT_OK';

use IO::Handle::Common;

@EXPORT    = qw'refstr dmsg array ARRAY';
@EXPORT_OK = @EXPORT;
our @EXPORT_SUB    = @EXPORT_OK;
our @EXPORT_COMMON = qw'';

use PadWalker qw'peek_my var_name';

use subs 'array';
use vars qw'@EXPORT @EXPORT_OK';

field $imported : reader;

APPLY($class_mop) {
    __PACKAGE__->apply($class_mop)
};

ADJUST {
    $self->import;
}

method apply : common ($class_mop) {
    $class->export_sub($class_mop);
    $class->export_common($class_mop);
}

method export_sub : common ($class_mop) {
    foreach my $common (@EXPORT_SUB) {
        $class_mop->add_method( $common, common => 1, \&$common );
    }
}

method export_common : common ($class_mop) {
    my $class = $class_mop->name;
    foreach my $common (@EXPORT_COMMON) {
        $class_mop->add_method( $common, common => 1, sub { $class->$common } );
    }
}

sub refstr ($in) {
    reftype($in) || '';
}

sub ARRAY (@in) {
    my @ret;

    foreach my ($var) (@in) {
        $var //= [];
        my $type = reftype($var);

        if ( !$type ) {
            push @ret, [$var];
        }
        elsif ( $type ne 'ARRAY' ) {
            my $name = PadWalker::var_name( 0, $var );
            die "\$name must be an ARRAY ref or a scalar value. (Got: $type)";
        }
        elsif ( $type eq 'ARRAY' ) {
            push @ret, $var;
        }
    }

    @ret;
}

*array = \&ARRAY;
