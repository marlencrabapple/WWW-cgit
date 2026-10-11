use Object::Pad ':experimental(:all)';

package WWW::cgit::Base;
role WWW::cgit::Base;

use utf8;
use v5.44;

use parent 'Exporter';
use vars qw'@EXPORT @EXPORT_OK';

use IO::Handle::Common;

@EXPORT = qw'refstr dmsg';

APPLY {
    use utf8;
    use v5.44;
    use WWW::cgit::Base;
};

ADJUST : params (%param) {
    use utf8;
    use v5.44;
    use WWW::cgit::Base;
};

sub refstr ($ref) {
    dmsg $ref;
    reftype($ref) // '';
}

