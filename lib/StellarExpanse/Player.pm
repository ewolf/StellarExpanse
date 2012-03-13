package StellarExpanse::Player;

use strict;

use base 'StellarExpanse::TakesOrders';

sub init {
    my $self = shift;
    $self->SUPER::init();
    $self->set_ready( 0 );
    $self->set_owner( $self );
}

sub mark_as_ready {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $turn = $self->get_turn();
    my $game = $self->get_game();
    if( $game->get_turn_number() != $data->{turn} ) {
        return { err => "Not on turn $data->{turn}" };
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

    my $ships   = $self->get_ships([]);
    my $sectors = $self->get_sectors([]);

    if( @$ships + @$sectors == 0 ) {
        $self->get_turn()->remove_from_players( $self );
    }

} #_defeat_check

1;


__END__
