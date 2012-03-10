package StellarExpanse::Turn;

#
# Holds the state of one turn of the game.
#

use strict;

use base 'Yote::Obj';

sub init {
    my $self = shift;
    $self->SUPER::init();
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
    return scalar( grep { ! $_->get_ready() } @{$self->_players()} ) == 0;
} #_check_ready

sub _increment_turn {
    my $self = shift;

    my $game = $self->get_game();
    
    # Back the previous turn up in a clone.
    my $clone = $self->_power_clone();
    my $turns = $game->get_turns();
    $turns->[$clone->get_turn_number()] = $clone;

    $self->set_turn_number( $clone->get_turn_number() + 1 );
    $self->_take_turn();

    $turns->[$self->get_turn_number()] = $self;
    $game->set_turn( $self );
    $game->set_turn_number( $self->get_turn_number() );

    # unready
    for my $player (@{$self->_players()}) {
        $player->set_ready( 0 );
    } 

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
    #    * check for changes in sector ownership
    #    * check bombardment attack
    #    * build    
    #    * repair (ship in sector)
    #    * give (players give to each other resources and sectors)
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

    my $players = $self->_players();
    for my $player (@$players) {
        $player->_give();
    }

    for my $sector (@$sectors) {
        $sector->_produce();
    }

    #
    # defeat check and refresh player maps
    #
    for my $player (@$players) {
        $player->_defeat_check();
        my $ps = $player->get_sectors();
        my $chart = $player->get_starchart();
        for my $ps (@$ps) {
            $chart->_update( $ps );
        }
    }

    # victory check
    if( 2 > (grep { $_->get_concede() } @$players) ) {
        $self->get_game()->_end();
    }    

} #_take_turn

1;

__END__
