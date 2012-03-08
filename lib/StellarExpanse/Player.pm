package StellarExpanse::Player;

use strict;

sub init {
    my $self = shift;
    $player->set_orders([]);
    $player->set_ready([]);
}

sub submit_orders {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $turn = $self->get_turn();
    if( $data->{turn} == $game->get_turn() ) {
        $player->set_orders( $data->{orders} );
        return { msg => "Submitted orders for turn ".$data->{turn} };
    } else {
        return { err => "Turn already over for these orders" };
    }
} #submit_orders

sub mark_as_ready {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $turn = $self->get_turn();
    my $game = $self->get_game();
    if( $game->get_turn() > $data->{turn} ) {
        return { err => "Turn $data->{turn} already over" };
    }
    $self->set_ready( $data->{ready} );
    if( $turn->_check_ready() ) {
        $turn->_increment_turn();
    }
    return { msg => "Set Ready to " . $data->{ready} };    
} #mark_as_ready

sub _notify {
    my( $self, $msg ) = @_;
    $self->add_to_notifications( $msg );
} #_notify

sub _give {
    my $self = shift;

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
		$self->revove_from_sectors( $sector );
		$sector->set_owner( $to );
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

    

} #_defeat_check

1;
