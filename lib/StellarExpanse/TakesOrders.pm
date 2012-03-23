package StellarExpanse::TakesOrders;

use StellarExpanse::Order;

use base 'Yote::Obj';

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->set_pending_orders([]);
    $self->set_completed_orders([]);
}

sub new_order {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $player = $self->get_game()->_find_player( $acct );
    unless( $player->is( $self->get_owner() ) || $player->is( $self ) ) {
        return { err => "Player may not order this object" };
    }
    if( $data->{turn} != $self->get_game()->get_turn_number() ) {
        return { err => "order given for wrong turn" };
    }
    
    my $ord = new StellarExpanse::Order();
    $ord->absorb( $data );
    $ord->set_subject( $self );
    $self->add_to_pending_orders( $ord );

    return { msg => "gave order", r => $ord };
} #new_order

1;

__END__
