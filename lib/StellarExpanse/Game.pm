package StellarExpanse::Game;

use strict;

use StellarExpanse::Game;

use base 'Yote::Obj';

#
# Returns the player object associated with the account, if any.
#
sub find_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    return $self->get_players({})->{$acct->get_handle()};
} #find_player

#
# Adds the account to this game, creating a player object for it.
#
sub add_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $players = $self->get_players({});
    if( $players->{$acct->get_handle()} ) {
        return { err => "account already added to this game" };
    }
    if( $self->needs_players() ) {
        my $player = new Yote::Obj;
        if( $data->{name} ) {
            $player->set_name( $data->{name} );
        }
        $players->{$acct->get_handle()} = $player;
        $acct_root->add_to_my_joined_games( $self );

        if( $self->needs_players() ) { #see if the game is now full
            return { msg => "added to game" };
        } else {
            $self->set_active( 1 );
            $self->get_app()->remove_from_pending_games( $self );
            $self->get_app()->add_to_active_games( $self );
	    $self->_start();
            return { msg => "added to game, which is now starting" };
        }
    }
    return { err => "game is full" };
} #add_player

#
# Removes the account from this game
#
sub remove_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $players = $self->get_players({});
    if( !$players->{$acct->get_handle()} ) {
        return { err => "account not a member of this game" };
    }
    if ($self->get_active()) {
        return { err => "cannot leave an active game" };
    }
    $acct_root->remove_from_my_joined_games( $self );
    delete $players->{$acct->get_handle()};
    return { msg => "player removed from game" };
}

#
# Returns number of players needed by game.
#
sub needs_players {
    my $self = shift;
    my $xx = $self->get_players({});
    my %x;
    if (ref($xx) eq 'HASH')  {
        %x = %{$xx};
    }
    else {
        eval { %x = %{$xx->[1]} };
    }
    return $self->get_number_players() - scalar( %x );
} #needs_players

#
# Called automatically upon the last person joining
#
sub _start {
    my $self = shift;

    
} #_start

sub submit_orders {
    my( $self, $data, $acct ) = @_;
    my $game = fetch( $data->{game} );
    my $player = $game->get_player( $acct );
    if( $player ) {
        if( $data->{turn} == $game->get_turn() ) {
            $player->get_orders([])->[$data->{turn}] = $data->{orders};
            return { msg => "Submitted orders for turn ".$data->{turn} };
        } else {
            return { err => "Turn already over for these orders" };
        }
    }
    return { err => "Not part of this game" };
} #submit_orders

sub get_orders {
    my( $self, $data, $acct ) = @_;
    my $game = fetch( $data->{game} );
    my $player = $game->get_player( $acct );
    if( $player ) {
        my $orders = $player->get_orders([])->[$game->get_turn()];
        return { d => $orders, msg => "got orders for turn ".$game->get_turn() };
    }
    return { err => "Not part of this game" };
} #get_orders

sub mark_as_ready {
    my( $self, $data, $acct ) = @_;
    my $game = fetch( $data->{game} );    
    my $player = $game->get_player( $acct );
    if( $player ) {
        if( $game->get_turn() > $data->{turn} ) {
            return { err => "Turn $data->{turn} already over" };
        }
        $player->get_ready([])->[$game->get_turn()] = $data->{ready};
        if( $game->is_ready() ) {
            $game->take_turn();
        }
        return { msg => "marked as".($data->{ready}?" ready ":" unready ")." for turn ".$game->get_turn() };
    }
    return { err => "Not part of this game" };
    
} #mark_as_ready

1;
