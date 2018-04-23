package SG::Dummy;

#
# Dummy user to prevent timing oracle.
#

use strict;
use warnings;

use Data::ObjectStore;
use SG::Player;
use base 'SG::Player';

use Digest::MD5;

#always returns false
sub _checkpw {
    my( $self, $pw ) = @_;
    $self->SUPER::_checkpw($pw);
    0;
}


1;
