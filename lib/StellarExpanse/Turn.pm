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
# List of joined players in the game this turn.
#
sub _players {
    my $self = shift;
    return [values %{ $self->get_players() }];
} #_players

#
# If all the players are ready, take the turn.
#
sub _check_ready {
    my $self = shift;
    return scalar( grep { ! $_->get_ready() } @{$self->{players}} ) == 0;
} #_check_ready

sub _increment_turn {
    my $self = shift;
    
    # orders have been given to this turn for next turn. They are copied with the clone, then used in _take_turn
    my $clone = $self->_power_clone();
    $clone->_take_turn();
    my $game = $self->set_game();
    $game->add_to_turns( $clone );
    $game->set_turn( $game->get_turn() + 1 );
    
} #_increment_turn

sub _take_turn {
    my $self = shift;

    # 
    # The turn taking process starts right after a turn has been cloned
    #    * unload
    #    * load
    #    * fire
    #    * death check
    #    * heal (ships damage control)
    #    * move
    #    * check for changes in system ownership
    #    * check bombardment attack
    #    * build    
    #    * repair (ship in system)
    #    * give (players give to each other resources and systems)
    # This is now a new turn in a state ready to play, so
    #    * player defeat check
    #    * unset all orders for ships,players and sectors
    #    * victory check
    #
    my $ships = $self->get_ships([]);
    for my $ship (@$ships) {
        $ship->_unload();
    }
    for my $ship (@$ships) {
        $ship->_load();
    }

    for my $ship (@$ships) {
        $ship->_fire();
    }

    for my $ship (@$ships) {
        $ship->_death_check();
        $ship->_damage_control();
    }

    for my $ship (@$ships) {
        $ship->_move();
    }

    my $sectors = $self->get_sectors([]);
    for my $sector (@$sectors) {
        $sector->_check_owner_and_bombardment();
	$sector->_build();
    }

    for my $ship (@$ships) {
        $ship->_repair();
    }

    my $players = $self->get_players([]);
    for my $player (@$players) {
        $player->_give();
        $player->_defeat_check();
    }

    # victory check
    if( 2 > (grep { $_->get_concede() } @$players) ) {
        $self->get_game()->_end();
    }    

    # unset orders :
    for my $ship (@{$self->get_ships([])}) {
        $ship->set_orders([]);
    }

} #_take_turn

1;

__END__
