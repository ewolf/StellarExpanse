package StellarExpanse::Sector;

use strict;
use StellarExpanse::TakesOrders;

use base 'StellarExpanse::TakesOrders';

# fields :
#     name     - string
#     game     - StellarExpanse::Game
#     ships    - list of StellarExpanse::Ship
#     links    - hash of sector id -> StellarExpanse::Sector
#     owner    - StallarExpanse::Player
#     indict   - boolean 
#     currprod - int
#     maxprod  - int ( max production this sector can use )
#     buildcap - int

sub _init {
    my $self = shift;
    $self->SUPER::_init();
    $self->set_ships([]);
    $self->set_links({});
    $self->set_maxprod( 0 );
    $self->set_currprod( 0 );
    $self->set_buildcap( 0 );
}

sub can_build_items {
    my( $self, $data, $acct ) = @_;
    return [ grep { $_->get_size() <= $self->get_buildcap() }  @{ $self->get_owner()->get_can_build() } ];
}

#
# Notifies any ships or sector owners of an occurance.
#
sub _notify {
    my( $self, $msg ) = @_;
    my $owner = $self->get_owner();
    if( $owner ) {
        $owner->_notify( $msg );
    }
    my $ships = $self->get_ships();
    for my $ship (@$ships) {
        $ship->_notify( $msg );
    }
    
} #_notify

#
#  Used in setup
#
sub _link_sectors {
    my( $self, $other ) = @_;
    die "Can only link a sector to a sector" unless $other->isa( 'StellarExpanse::Sector' );
    my $Alinks = $self->get_links();
    my $Blinks = $other->get_links();
    $Alinks->{$other->{ID}} = $other;
    $Blinks->{$self->{ID}} = $self;
    return undef;
}

sub _links {
    my $self = shift;
    return [values %{$self->get_links()}];
} #links

# takes an id of a sectors and returns true if the two link together.
sub _valid_link {
    my( $self, $other ) = @_;
    my $id = $other->{ID};
    my $links = $self->get_links();
    if( $links->{$id} ) {
        my $olinks = $links->{$id}->get_links();
        return $olinks->{$self->{ID}} && $id == $links->{$id}{ID};
    }
    return 0;
} #_valid_link

sub _check_owner_and_bombardment {
    my $self = shift;
    $self->set_indict( 0 ); #reset indict flag

    # find the power affecting this sector
    my $ships = $self->get_ships();
    my( %player2attack_power );
    for my $ship (@$ships) {
        if( $ship->get_attack_beams() ) {
            $player2attack_power{$ship->get_owner()->{ID}} += $ship->get_attack_beams();
        }
    }
    # check for uncontested sector
    if( scalar( keys %player2attack_power ) == 1 ) {
        my( $attack_player_id ) = ( keys %player2attack_power );
        my $attacker = Yote::ObjProvider::fetch( $attack_player_id );
        next unless $player2attack_power{$attack_player_id};
        
        
        #
        # Can change hands if there is only one force in the sector and there is no industry.
        #
        if( ! $attacker->_is( $self->get_owner() ) ) {
            if( $self->get_currprod() < 1 ) {
                my $old_owner = $self->get_owner();
                if( $old_owner ) {
                    $old_owner->remove_from_sectors( $self );
                }
                $attacker->add_to_sectors( $self );
                $self->_notify( $attacker->get_name()." conquered ".$self->get_name() );
                $self->set_owner($attacker);
            } #conquoring
            else {

                #bombardment
                my $original = $self->get_currprod();
                $self->set_currprod(  $self->get_currprod() - $player2attack_power{$attack_player_id} );
                $self->set_indict( 1 );
                if( $self->get_currprod() < 1 ) {
                    $self->set_currprod( 0 ); #minimum is zero
                }
                my $newprod = $self->get_currprod();

                $self->_notify( $attacker->get_name()." bombarded ".$self->get_name()." bringing it to production $newprod from $original" );
            } #bombardment
        } #if not owner
    } #if uncontested

} #_check_owner_and_bombardment 

sub _build {
    my $self = shift;
    my $player = $self->get_owner();
    my $orders = $self->get_pending_orders();    
    for my $order (grep { $_->get_order() eq 'build' } @$orders) {
	$order->set_location( $self );
        my $prototype = $order->get_ship();
        if( $prototype ) {
            if( $prototype->get_type() =~ /^(SHIP|OIND|IND|TECH)$/ ) {
                if( $prototype->get_tech_level() <= $player->get_tech_level() ) {                
                    my $quantity = $order->get_quantity() || 1;
                    my $actually_built = 0;
                    my $cost = $prototype->get_cost();
                    for( 1..$quantity ) {
                        if( $self->get_buildcap() >= $prototype->get_size() ) {
                            if( $cost <= $player->get_resources() ) {
                                if( $prototype->get_type() eq 'SHIP' || $prototype->get_type() eq 'OIND' ) {
                                    my $new_ship = Yote::ObjProvider::power_clone($prototype);
                                    $new_ship->set_home_sector( $self );
                                    $new_ship->set_origin_sector( $self );
                                    $new_ship->set_owner( $player );
                                    $new_ship->set_game( $self->get_game() );
                                    $new_ship->set_hitpoints( $new_ship->get_defense() );
                                    $new_ship->set_free_rack( $new_ship->get_racksize() );
                                    $new_ship->set_location( $self );

                                    $self->add_to_ships( $new_ship );
                                    $self->get_game()->_current_turn()->add_to_ships( $new_ship );
                                    $player->add_to_ships( $new_ship );
                                    $player->set_resources( $player->get_resources() - $cost );
                                    $order->add_to_built( $new_ship );
                                    $actually_built++;
                                }
                                elsif( $prototype->get_type() eq 'IND' ) {
                                    if( $self->get_currprod() < $self->get_maxprod() ) {
                                        $self->set_currprod($self->get_currprod() + 1 );
                                        $player->set_resources( $player->get_resources() - $cost );
                                        $actually_built++;
                                    } 
                                    else {
                                        unless( $actually_built ) {
                                            $order->_resolve( "Already at max production" );
                                            return;
                                        }
                                    }
                                }
                                elsif( $prototype->get_type() eq 'TECH' ) {
                                    my $current = $player->get_tech_level();
                                    my $provided = $prototype->get_provides_tech();
                                    if( $provided > $current ) {
                                        $player->_change_tech_level( $provided );
                                        $player->set_resources( $player->get_resources() - $cost );
                                        $order->_resolve( "Upgraded to tech ".$player->get_tech_level()." from $current for a cost of $cost", 1 );
                                    } else {
                                        $order->_resolve( "Upgrading to tech $provided has no effect" );
                                    }
                                    return;
                                }
                                #
                                # calculate the maximum build size. It is 3 * the production + 
                                # number of orbital industries here.
                                #
                                $self->set_buildcap( 3 * $self->get_currprod() );
                                my $ships_here = $self->get_ships();
                                for my $industry_ship (grep { $_->get_type() eq 'OIND' } @$ships_here) {
                                    $self->set_buildcap( 1 + $self->get_buildcap() );
                                }
                            }
                            else {
                                if( $actually_built ) {
                                    $order->_resolve("Built ". $actually_built . " of $quantity " . $prototype->get_name(), 1 );
                                } 
                                else {   
                                    $order->_resolve( "Not enough resources to build " . $prototype->get_name() );
                                }
                                return;
                            }
                        }
                        else {
                            if( $actually_built ) {
                                $order->_resolve("Built ". $actually_built . " of $quantity " . $prototype->get_name(), 1 );
                            } 
                            else {   
                                $order->_resolve("Can't build " . $prototype->get_name() . "Not enough build capacity.");
                            }
                            return;
                        }
                    } #each times build
                    $self->_notify( "Built $quantity ".$prototype->get_name()." in location ".$self->get_name()." for a cost of $cost" );
                    $order->_resolve( "Built $quantity ".$prototype->get_name()." in location ".$self->get_name()." for a cost of $cost", 1 );
                } 
            }
            else { #enough tech
                $order->_resolve( "Tech level not high enough to build " . $prototype->get_name() );
            }
        } 
        else {
            $order->_resolve( "Unknown prototype type ".$prototype->get_type() );
        }
    } #each build order

} #_build

sub _produce {
    my $self = shift;
    my $owner = $self->get_owner();
    if( $owner ) {
        $owner->set_resources( $owner->get_resources() + $self->get_currprod() );
    }
    
} #_produce

1;

__END__


=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Eric Wolf

=cut
