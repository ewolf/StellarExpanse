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
1;
