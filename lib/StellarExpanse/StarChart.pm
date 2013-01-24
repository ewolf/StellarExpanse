package StellarExpanse::StarChart;

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
        my $recorded_here = $node->get_ships();
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
            $node->add_to_notes( { msg        => "Updated",
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
        $node->set_player( $self->get_player() );

	# add connecting nodes maybe?
	$node->set_name( $sector->get_name() );
	my $sector_links = $sector->get_links();
	my $node_links = $node->get_links( {} );
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
        $node->add_to_notes( { msg        => "Discovered",
                               turn       => $self->get_game()->get_turn_number(),
                               owner      => $sector->get_owner(),
                               production => $sector->get_currprod(),
                               ships      => $sector->get_ships(),
                             } );
    }

    $node->set_seen_production( $sector->get_currprod() );
    $node->set_seen_owner( $sector->get_owner() );
    $node->set__seen_ships( $ships_here );

} #_update

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
