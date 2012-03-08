package StellarExpanse;

use base 'Yote::Obj';

sub _notify {
    my( $self, $msg ) = @_;
    $self->get_owner()->_notify( "Ship " . $self->get_name() . " in sector " . $self->get_location->get_name() . " reports : $msg " );
} #notify

#
# Unload me from a carrier.
#
sub _unload {
    my $self = shift;
    my $orders = $self->get_orders([]);
    my $carrier = $self->get_carrier();
    if( $carrier ) {
n        if( grep { $_->get_order() eq 'unload' } @$orders) {
            my $loc = $carrier->get_location();
            $self->set_location( $loc );
            $loc->add_to_ships( $self );
            $carrier->remove_from_carried( $self );
            # TODO : find a good method to report back status of orders, attached to ship and player
            for my $order (grep { $_->get_order() eq 'unload' } @$orders) {
                $order->_resolve("Unloaded from " . $carrier->get_name(), 1);
            }
        }
    }
    for my $order (grep { $_->get_order() eq 'unload' } @$orders) {
        $order->_resolve("Can't unload. Not loaded on a carrier.");
    }
} #_unload

#
# Load me onto a carrier.
#
sub _load {
    my $self = shift;
    my $orders = $self->get_orders([]);
    my( $ord ) = grep { $_->get_order() eq 'load' } @$orders;
    if( $ord ) {
        my $loc = $self->get_location();
        my $carrier = $ord->get_carrier();
        if( $carrier && $carrier->get_owner()->is( $self->get_owner() ) ) {
            #check for room
            if( $self->get_carrier() ) {
                $ord->_resolve( "Already on a carrier. Must unload before moving to an other" );
            }
            elsif( $carrier->get_free_rack() >= $self->get_size() ) {
                $carrier->add_to_carried( $self );
                $self->set_carrier( $carrier );
                $self->set_location( undef );
                $loc->remove_from_ships( $self );
                $ord->_resolve( "Loaded onto " . $carrier->get_name(), 1 );
            } else {
                $ord->_resolve( "Not enough room on carrier" );
            }
        } else {
            $ord->_resolve( "Unable to load onto carrier. Carrier not owned by you" );
        }
    }
} #_load

sub _death_check {
    my $self = shift;

    return if $self->{death_check_done};
    $self->{death_check_done} = 1;
    if( $self->get_hitpoints() < 1 ) {
        my $loc = $self->get_location();
        if( $loc ) {
            $loc->_notify( "Ship " . $self->get_name() " ( " . $self->get_owner()->get_name() . " ) was destroyed in sector " . $loc->get_name() );
            $loc->remove_from_ships( $self );
            $self->get_owner()->get_turn()->remove_from_ships( $self );
            $self->get_owner()->remove_from_ships( $self );
            $self->{is_dead} = 1;
        }
        my $carried = $self->get_carried([]);
        for my $carried (@$carried) {
            $carried->set_hitpoints( 0 );
            $carried->_death_check();
        }
    }
} #_death_check

sub _damage_control {
    my $self = shift;
    my( $def, $dc, $hp ) = ( $self->get_defense(), $self->get_damage_control(), $self->get_hitpoitns() );
    return if $self->{is_dead} || $hp >= $def;
    my $needs = $def - $hp;
    my $heal = $dc > $needs ? $needs : $dc;
    $self->set_hitpoints( $hp + $heal );
} #_damage_control

sub _repair {
    my $self = shift;
    return if $self->{is_dead};

    my $orders = $self->get_orders([]);
    my $player = $self->get_owner();
    for my $ord (grep { $_->get_order() eq 'repair' } @$orders) {
        my $rus    = $player->get_resources();
        my $hp     = $self->get_hitpoints();
        my $def    = $self->get_defense();
        my $needs  = $def - $hp;
        if( $needs == 0 ) {
            $ord->_resolv( "Ship is not damaged", 1 );
            next;
        }
        my $amt = $ord->get_repair_amount();
        if( $amt == 0 ) {
            $ord->_resolv( "No repair value specified" );
            next;
        }
        if( $rus < int(.6 + $amt / 2) ) {
            $amt = 2 * $rus;
        }
        if( $amt > 0 ) {
            $amt = $amt < $needs ? $amt : $needs;
            my $cost = $int(.6+$amt*2);
            $player->set_resources( $rus - $cost );
            $self->set_hitpoints( $hp + $amt );
            $self->get_location()->_notify( $self->get_name() . " repaired some damage at " . $self->get_location()->get_name() );
            $ord->_resolve( "Repaired $amt damage", 1 );
        } else {
            $ord->_resolve( "Not enough resources" );
        }
    } #each repair order
    
} #_repair

sub _fire {
    my $self = shift;
    $self->{targets} = $self->get_targets();
    $self->{beams}   = $self->get_attack_beams();
    my $orders = $self->get_orders([]);
    my( @fire_orders ) = grep { $_->get_order() eq 'fire' } @$orders;
    for my $ord ( @fire_orders ) {
        my $targ = $ord->get_target();
        if( $targ ) {
            my $loc = $self->get_location();
            if( $loc->is( $targ->get_location() ) ) {
                if( $self->{targets} > 0 ) {
                    if( $self->{beams} > 0 ) {
                        my $beam_req = $ord->get_beams();
                        my $beams = $self->{beams} < $beam_req ? $self->{beams} : $beam_req;
                        $targ->set_hitpoints( $targ->get_hitpoints() - $beams );
                        $ord->_resolve( "Attacked " . $targ->get_name() . " (" . $targ->get_owner()->get_name() . " ) with $beams attack beams", 1 );
                        $loc->_notify( $self->get_name() . " ( " . $self->get_owner()->get_name() . " ) attacked ". $targ->get_name() . " (" . $targ->get_owner()->get_name() . " ) with $beams attack beams" );
                    } else {
                        $ord->_resolve( "Out of Attack Power" );
                    }
                } else {
                    $ord->_resolve( "Out of Attacks" );
                }
            } else {
                $ord->_resolve( "Target not found in this sector." );
            }
        } else {
            $ord->_resolve( "No target specified" );
        }
    }
} #_fire

sub _move {
    my $self = shift;
    $self->{move} = $self->get_jumps();
    my $orders = $self->get_orders([]);
    my( @move_orders ) = grep { $_->get_order() eq 'move' } @$orders;
    for my $ord (@move_orders) {
        my( $loc, $from, $to ) = ( $self->get_location(), $ord->get_from(), $ord->get_to() );
        if( $loc ) {
            if( $loc->is( $from ) ) {
                if( $from->_valid_link( $to ) ) {
                    if( $self->{move} > 0 ) {
                        $self->{move}--;
                        $self->set_location ( $to );
                        $to->add_to_ships( $self );
                        $from->remove_from_ships( $self );
                        $from->_notify( $self->get_name() . " jumped out of system " . $loc->get_name() );
                        $to->_notify( $self->get_name() . " jumped into system " . $to->get_name() );
                        $ord->_resolve( "moved from " . $from->get_name() . " to " . $to->get_name(), 1  );
                    } else {
                        $ord->_resolve( "out of movement" );
                    }
                } else {
                    $ord->_resolve( $from->get_name() " does not link to " . $to_get_name() );
                }
            } else {
                $ord->_resolve( "Not in " . $loc->get_name() );
            }
        } else {
            $ord->_resolve( "Must specify from which sector" );
        }
    }
    
} #_move

1;
