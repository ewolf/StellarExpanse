package StellarExpanse::Player;

use strict;

use base 'StellarExpanse::TakesOrders';

# fields - 
#    ready       - boolean
#    owner       - ( self, have to see why on earth this is there )
#    Last_sector - StellarExpanse::Sector
#    tech_level  - int
#    can_build   - list of StellarExpanse::Ships
#    resources   - int
#    pending_orders - list of StellarExpanse::Order

sub _init {
    my $self = shift;
    $self->SUPER::_init();
    $self->set_ready( 0 );
    $self->set_owner( $self );
    $self->set_Last_sector( undef );
    $self->set_notifications([]);
    $self->set_sectors([]);
    $self->set_tech_level( 0 );
    $self->set_resources( 0 );
    $self->set_ships([]);
    $self->set_all_completed_orders( [] );
}

sub load_data {
    my $self = shift;
    my $turn_number = $self->get_game()->get_turn_number();
    my $chart = $self->get_starchart();

    return [ $self->get_ships(),
	     @{ $self->get_ships() },
	     @{[map { @{$_->get_pending_orders()} } @{$self->get_ships() }]},
	     $self->get_all_completed_orders(),
	     $self->get_pending_orders(),
	     @{ $self->get_pending_orders() },
	     @{ $self->get_all_completed_orders()->[$turn_number] || []  },
	     $self->get_notifications(),
	     $self->get_Last_sector(),
	     $self->get_sectors(),
	     @{ $self->get_sectors() },
	     @{[map { $_->get_pending_orders(), @{$_->get_pending_orders() || [] } } @{$self->get_sectors() }]},
	     @{[ map { $_->get_links() } @{$self->get_sectors()} ]},
	     @{[ map { values %{$_->get_links()} } @{$self->get_sectors()} ]},
	     @{[ map { @{$_->get_ships()} } @{$self->get_sectors()}]},
	     $self->get_pending_orders(),
	     @{ $self->get_pending_orders() },
	     $chart,
	     $chart->get_map(),
	     @{ [values %{$chart->get_map()}] },
	     @{[ map { $_->get_links() } values %{$chart->get_map()} ] },
	     @{[ map { $_->get_notes(), @{ $_->get_notes() || [] } } values %{$chart->get_map()} ] },
	     @{[ map { values %{$_->get_links()||{}} } values %{$chart->get_map()} ] },
	];
}

sub mark_as_ready {
    my( $self, $data, $acct ) = @_;
    my $turn = $self->get_turn();
    my $game = $self->get_game();
    if( $game->get_turn_number() != $data->{turn} ) {
        die "Not on turn $data->{turn}";
    }
    $self->set_ready( $data->{ready} );
    if( $turn->_check_ready() ) {
        $turn->_increment_turn();
    }
    return $game->get_turn_number();
} #mark_as_ready

sub _change_tech_level {
    my( $self, $level ) = @_;
    $self->set_tech_level( $level );
    $self->set_can_build( [ grep { $_->get_tech_level() <= $level } @{ $self->get_game()->get_flavor()->get_ships() } ] );
}

sub _notify {
    my( $self, $msg ) = @_;
    $self->add_to_notifications( $msg );
} #_notify

sub _give {
    my $self = shift;

    my $orders = $self->get_pending_orders();
    for my $ord ( grep { $_->get_order() eq 'give_resources' } @$orders ) {
        my $to = $ord->get_recipient();
        if( $to ) {
            my $resources = $self->get_resources();
            my $amt = $ord->get_amount();
            my $give = $resources > $amt ? $amt : $resources;
            if( $give > 0 ) {
                $to->set_resources( $to->get_resources() + $give );
                $self->set_resources( $resources - $give );
                $ord->_resolve( "Gave $amt to " . $to->get_name(), 1 );
            } else {
                $ord->_resolve( "Must give postive amount" );
            }
        } else {
            $ord->_resolve( "must specify recipient" );
        }    
    } #each give_resources order

    for my $ord ( grep { $_->get_order() eq 'give_sector' } @$orders ) {
        my $to = $ord->get_recipient();
        if( $to ) {
            my $sector = $ord->get_sector();
            if( $sector && $self->is( $sector->get_owner() ) ) {
                $to->add_to_sectors( $sector );
                $self->remove_from_sectors( $sector );
                $sector->set_owner( $to );
                $sector->set___creator( $to->get_account() );
                $ord->_resolve( "Gave sector " . $sector->get_name() . " to " . $to->get_name(), 1 );
            } else {
                $ord->_resolve( "Must give postive amount" );
            }
        } else {
            $ord->_resolve( "must specify recipient" );
        }    
        
    } #each give_sector order
    
} #_give

sub _defeat_check {
    my $self = shift;

    my $ships   = $self->get_ships([]);
    my $sectors = $self->get_sectors([]);

    if( @$ships + @$sectors == 0 ) {
        $self->get_turn()->remove_from_players( $self );
    }

} #_defeat_check

1;


__END__
