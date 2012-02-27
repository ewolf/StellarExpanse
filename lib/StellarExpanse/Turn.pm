package StellarExpanse::Turn;

#
# Holds the state of one turn of the game.
#

use strict;

use base 'Yote::Obj';

sub init {
    my $self = shift;
    $self->set_players({});
}

#
# List of joined players
#
sub players {
    my $self = shift;
    return [values %{ $self->get_players() }];
}

1;

__END__
