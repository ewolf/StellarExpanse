package StellarExpanse::StarChart;

use strict;

use base 'Yote::Obj';

sub _init {
    my $self = shift;
    $self->set_map({});
    $self->set__seen_ships([]);
}

sub _update {
    my( $self, $sector ) = @_;

    my $map = $self->get_map();

    my $ships_here = [grep { ! $self->get_owner()->_is( $_->get_owner() ) } @{$sector->get_ships([])}];

    my $node = $map->{$sector->{ID}};
    if( $node && $node->get_discovered() ) {
        my $recorded_here = $node->get__seen_ships();
        my $different_ships = scalar(@$recorded_here) != scalar(@$ships_here);
        unless( $different_ships ) {
            my( %ids_here ) = map { $_->{ID} => 1 } @$ships_here;
            for my $recorded_ship ( @$recorded_here ) {
                unless( $ids_here{ $recorded_ship->{ID} } ) {
                    $different_ships = 1;
                    last;
                }
            }
        }

        if( $different_ships || $node->get_seen_production() != $sector->get_currprod() || ( $node->get_seen_owner() && ( ! $node->get_seen_owner()->_is( $node->get_seen_owner() ) ) ) || $node->get_seen_owner() ) {
            $node->add_to_notes( { msg        => "Updated on turn " . $self->get_game()->get_turn_number(),
                                   turn       => $self->get_game()->get_turn_number(),
                                   owner      => $sector->get_owner(),
                                   production => $sector->get_currprod(),
                                   ships      => $sector->get_ships(),
                                 } );
        }
    }
    else {
	$node ||= new Yote::Obj();
	$node->set_discovered( 1 );
        $node->set_game( $self->get_game() );

	# add connecting nodes maybe?
	$node->set_name( $sector->get_name() );
	my $sector_links = $sector->get_links();
	my $node_links = $node->get_links( {} );

	# make nodes for links from thie sector unles there is a node for them already

	for my $other_sector_id (keys %$sector_links) {
	    my $other_sector = Yote::ObjProvider::fetch( $other_sector_id );
	    my $other_node   = $map->{ $other_sector_id };
	    unless( $other_node ) {
		$other_node = new Yote::Obj();
		$other_node->set_name( $other_sector->get_name() );
		$other_node->set_discovered( 0 );
		$map->{ $other_sector_id } = $other_node;
	    }
	    $node_links->{ $other_sector->{ID} } = $other_node;
	}

        $map->{$sector->{ID}} ||= $node;
        $node->add_to_notes( { msg        => "Discovered on turn " . $self->get_game()->get_turn_number(),
                               turn       => $self->get_game()->get_turn_number(),
                               owner      => $sector->get_owner(),
                               production => $sector->get_currprod(),
                               ships      => $sector->get_ships(),
                             } );
    }

    $node->set_seen_production( $sector->get_currprod() );
    $node->set_seen_max_production( $sector->get_maxprod() );
    $node->set_seen_owner( $sector->get_owner() );
    $node->set__seen_ships( $ships_here );

} #_update

sub enemy_ships {
    my( $self, $sector_id, $acct ) = @_;
    # returns ships list if there are ships that can currently be seen here
    my $node = $self->get_map()->{ $sector_id };
    my $ret = [];
    if( $node ) {
	my $sector = Yote::ObjProvider::fetch( $sector_id );
	if( $sector ) {
	    my $sec_ships = $sector->get_ships();
	    my $e_ships = [];
	    my $has_own_ship = 0;
	    for my $sec_ship (@$sec_ships) {
		if( $sec_ship->get_owner()->_is( $self->get_owner() ) ) {
		    $has_own_ship = 1;
		} else {
		    push( @$e_ships, $sec_ship );
		}
	    }
	    if( $has_own_ship || $self->get_owner()->_is( $sector->get_owner() ) ) {
		$ret = $e_ships;
	    }
	}
    }
    return $ret;
}

sub _get_entry {
    my( $self, $sector ) = @_;

    return $self->get_map()->{$sector->{ID}};
} #_get_entry

#
# Checks if the sector has an entry in the chart.
#
sub _has_entry {
    my( $self, $sector ) = @_;

    return defined $self->get_map()->{$sector->{ID}} && $self->get_map()->{$sector->{ID}}->get_discovered();
} #_has_entry


1;

__END__
