package StellarExpanse::TakesOrders;

use strict;

use StellarExpanse::Order;

use base 'Yote::UserObj';

sub _init {
    my $self = shift;
    $self->SUPER::_init();
    $self->set_pending_orders([]);
    $self->set_all_pending_orders([]);
    $self->set_completed_orders([[]]); # a list of lists : each turn number gets a list. turn zero has an empty list
}

sub new_order {
    my( $self, $data, $acct ) = @_;
    my $player = $self->get_game()->_find_player( $acct );

    unless( $player->_is( $self->get_owner() ) || $player->_is( $self ) ) {
        die "Player may not order this object";
    }
    if( $data->{turn} != $self->get_game()->get_turn_number() ) {
        die "order given for wrong turn";
    }
    
    my $ord = new StellarExpanse::Order();
    $ord->_absorb( $data );
    $ord->set_subject( $self );
    $ord->set___creator( $acct );
    $self->add_to_pending_orders( $ord );
    
    $self->get_owner()->add_to_all_pending_orders( $ord );

    return $ord;
} #new_order

sub remove_order {
    my( $self, $data, $acct ) = @_;
    my $player = $self->get_game()->_find_player( $acct );
    unless( $player->_is( $self->get_owner() ) || $player->_is( $self ) ) {
        die "Player may not remove this order";
    }
    if( $data->get_turn() != $self->get_game()->get_turn_number() ) {
        die "cannot remove order for wrong turn";
    }

    $self->remove_all_from_pending_orders( $data );
    
    $self->get_owner()->remove_all_from_all_pending_orders( $data );
    return $data;
} #remove_order

1;

__END__
