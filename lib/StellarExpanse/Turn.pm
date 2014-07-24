package StellarExpanse::Turn;

#
# Holds the state of one turn of the game.
#
# Data : players {}, ships [], sectors [], game StellarExpanse::Game, turn_number
#

use strict;

use base 'Yote::Obj';

sub _init {
     my $self = shift;
     $self->SUPER::_init();
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

sub _glean {
    my( $self, $thing, $translate ) = @_;
    
    my $new_thing;
    if( ref( $thing ) eq 'ARRAY' ) {
        $new_thing = [];
    } elsif( ref( $thing ) eq 'HASH' ) {
        $new_thing = {};
    } elsif( ref( $thing ) ) {
        $new_thing = $thing->new;    
        $new_thing->{ DATA } = { %{ $thing->{ DATA } } };
    } else {
        return $thing;
    }

    $translate->{ $self->_get_id( $thing ) } = $new_thing;
    
    return $new_thing
} #_glean

sub _clone {
    my $self = shift;

    my $translate = {};

    my $clone = $self->_glean( $self, $translate );

#    for my $thing ( $self->get_ships, map { $_, $_->get_pending_orders, @{ $_->get_pending_orders }, $_->get_carried } @{$self->get_ships([])} ) {
    for my $thing ( @{$self->get_ships([])}, $self->get_ships ) {
        my $x = $self->_glean( $thing, $translate );
#        print STDERR Data::Dumper->Dump([$thing,$x]);
    }

#    for my $thing ( $self->get_sectors, map { $_, $_->get_pending_orders, @{ $_->get_pending_orders } } @{$self->get_sectors([])} ) {
    for my $thing ( $self->get_sectors, map { $_, $_->get_ships} @{$self->get_sectors([])} ) {
        $self->_glean( $thing, $translate );
    }

#    for my $thing ( map { $_, $_->get_pending_orders, @{ $_->get_pending_orders }, $_->get_ships, $_->get_can_build, $_->get_sectors, $_->get_notifications, } values %{$self->get_players()} ) {
    for my $thing ( map { $_, $_->get_ships, $_->get_can_build, $_->get_sectors, $_->get_notifications } values %{$self->get_players()} ) {
        $self->_glean( $thing, $translate );
    }

    for my $thing ( values %$translate ) {
        if( ref( $thing ) eq 'ARRAY' ) {
            for( my $i=0; $i<@$thing; $i++ ) {
                my $val = $thing->[ $i ];
                if( ref( $val ) && $translate->{ $self->_get_id( $val ) } ) {
                    $thing->[ $i ] = $self->_get_id( $translate->{ $self->_get_id( $val ) } );
                }
            }
        }
        elsif( ref( $thing ) eq 'HASH' ) {
            for my $field ( keys %$thing ) {
                my $val = $thing->{ $field };
                if( ref( $val ) && $translate->{ $val } ) {
                    $thing->{ $field } = $self->_get_id( $translate->{ $self->_get_id( $val ) } );
                }
            }
        }
        elsif( ref( $thing ) ) {
            for my $field ( keys %{ $thing->{ DATA } } ) {
                my $val = $thing->{ DATA }{ $field };
                if(  $translate->{ $val } ) {
                    $thing->{ DATA }{ $field } = $self->_get_id( $translate->{ $val } );
                }
            }
        }
    }

    for my $sector ( @{$self->get_sectors([])} ) {
        my $new_sector = $translate->{ $sector->{ID} };
        my $old_links = $sector->get_links();
        my $new_links = {};
        for my $olsect ( values %$old_links ) {
            my $nwsect = $translate->{ $olsect->{ID} };
            $new_links->{ $nwsect->{ID} } = $nwsect;
        }
        $new_sector->set_links( $new_links );
    }

    my $newp = {};
    my $pl = $self->get_players;
    for my $name ( keys %$pl ) {
        my $pl = $pl->{ $name };
        $newp->{ $name } = $translate->{ $pl->{ ID } };
    }
    $clone->set_players( $newp );
    $clone->set_ships( $translate->{ $self->_get_id( $self->get_ships() ) } );

    return $clone;
} #_clone

sub _increment_turn {
    my $self = shift;

    my $game = $self->get_game();

    # Back the previous turn up in a clone.
    my $g_id  = Yote::ObjProvider::get_id($game);
    my $clone = $self->_clone;

    $self->_take_turn();

    $self->set_turn_number( $self->get_turn_number() + 1 );

    my $turns = $game->get__turns();
    $turns->[$clone->get_turn_number()] = $clone;

    $turns->[$self->get_turn_number()] = $self;
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
        $ship->_load_onto_carrier();
    }

    for my $ship (@$ships) {
        $ship->_fire();
    }

    for my $ship (@$ships) {
        $ship->_death_check();
    }
    for my $ship (@$ships) {
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

        # carried ships wont have a location
        $ship->get_owner()->get_starchart()->_update( $ship->get_location() ) if $ship->get_location();
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
