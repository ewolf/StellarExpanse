package StellarExpanse::Sector;

use strict;

use base 'Yote::Obj';

sub init {
    my $self = shift;
    $self->set_ships([]);
}

#
# Notifies any ships or system owners of an occurance.
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
    my $Alinks = $self->get_links({});
    my $Blinks = $other->get_links({});
    $Alinks->{$other->{ID}} = $other;
    $Blinks->{$self->{ID}} = $self;
    return undef;
}

# takes an id of a sectors and returns true if the two link together.
sub _valid_link {
    my( $self, $id ) = @_;
    my $links = $self->get_links();
    if( $links->{$id} ) {
        my $olinks = $links->{$id}->get_links();
        return $olinks->{$self->{ID}} && $id == $links->{$id}{ID};
    }
    return 0;
} #_valid_link

sub _valid_links {
    my $self = shift;
    my $seen = shift;
    my $links = $self->get_links();

    for my $key (keys %$links) {
        next if $seen->{$key};
        $seen->{$key} = 1;
        return 0 unless $self->_valid_link( $links->{$key} );
        return 0 unless $links->{$key}->_valid_links( $seen );
    }
    return 1;
} #_valid_links

sub _check_owner_and_bombardment {
    my $self = shift;
    $self->set_indict( 0 ); #reset indict flag

    # find the power affecting this system
    my $ships = $self->get_ships([]);
    my( %player2attack_power );
    for my $ship (@$ships) {
	if( $ship->get_attack_beams() ) {
	    $player2attack_power{$ship->get_owner()->{ID}} += $ship->get_attack_beams();
	}
    }

    # check for uncontested system
    if( scalar( keys %player2attack_power ) == 1 ) {
	my( $attack_player_id ) = ( keys %player2attack_power );
	my $attacker = Yote::ObjProvider::fetch( $attack_player_id );
	next unless $player2attack_power{$attack_player_id};
	
	
            #
            # Can change hands if there is only one force in the system and there is no industry.
            #
            if( ! $self->get_owner()->is( $attacker ) ) {
                if( $self->get_currprod() < 1 ) {
                    my $old_owner = $self->get_owner();
                    if( $old_owner ) {
                        $old_owner->remove_from_systems( $self );
                    }
                    $attacker->add_to_systems( $self );
		    $self->_notify( $attacker->get_name()." conquered ".$self->namestr() );
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
		    $self->_notify( $attacker->get_name()." bombarded ".$self->namestr()." bringing it to production $newprod from $original" );
                } #bombardment
            } #if not owner
    } #if uncontested

} #_check_owner_and_bombardment 

sub _build {
    my $self = shift;
    my $player = $self->get_owner();
    my $orders = $self->get_orders([]);    
    for my $order (grep { $_->get_order() eq 'build' } @$orders) {
	my $prototype = $order->get_ship();
	if( $prototype ) {
	    if( $self->get_buildcap() >= $prototype->get_size() ) {
		if( $prototype->get_tech_level() <= $player->get_tech() ) {
		    my $cost = $prototype->get_cost();
		    if( $cost <= $player->get_resources() ) {
			if( $prototype->get_type() eq 'SHIP' || $prototype->get_type() eq 'OIND' ) {
                                my $new_ship = $prototype->clone();
                                $new_ship->set_owner( $player );

                                $self->add_to_ships( $new_ship );
                                $new_ship->set_location( $self );

                                $player->add_to_ships( $new_ship );
                                $player->set_resources( $player->get_resources() - $cost );

				$self->_notify( "Built ".$new_ship->get_name()." in location ".$self->namestr()." for a cost of $cost", 1 );
			}
			elsif( $prototype->get_type() eq 'IND' ) {
			    if( $self->get_currprod() < $self->get_maxprod() ) {
				$self->set_currprod($self->get_currprod() + 1 );
                                    $msg->{result} = 'success';
                                    $msg->{msg} = "Built industry in location ".$loc->namestr()." for a cost of $cost";
                                    $player->set_rus( $player->get_rus() - $cost );

                                } else {
                                    $msg->{err} = "Already at max production";
                                }
                            }
                            elsif( $prototype->get_type() eq 'TECH' ) {
                                $player->set_tech( $prototype->get_tech_level() + 1 );
                                $player->set_rus( $player->get_rus() - $cost );
                                $msg->{result} = 'success';
                                $msg->{msg} = "Upgraded to tech ".$player->get_tech()." for a cost of $cost";
                            }
                            else {
                                $msg->{err} = "Unknown prototype type ".$prototype->get_type();
                            }
                            #
                            # calculate the maximum build size. It is 3 * the production + 
                            # number of orbital industries here.
                            #
                            $loc->set_buildcap( 3 * $loc->get_currprod() );
                            my $ships_here = $loc->get_ships([]);
                            for my $here_ship (@$ships_here) {
                                if( $here_ship->get_prototype('type') eq 'OIND' ) {
                                    $loc->set_buildcap( 1 + $loc->get_buildcap() );
                                }
                            }
		    } else {
			$order->_resolve( "Not enough resources to build " . $prototype->get_name() );
		    }
		} else { #enough tech
		    $order->_resolve( "Tech level not high enough to build " . $prototype->get_name() );
		}
	    } else {
		$order->_resolve("Can't build " . $prototype->get_name() . "Not enough build capacity.");
	    }
	} else {
	    $order->_resolve("Can't build. Nothing specified to build.");
	}
    } #each build order
} #_build

1;

__END__


=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Eric Wolf

=cut
