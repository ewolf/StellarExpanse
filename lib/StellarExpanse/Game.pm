package StellarExpanse::Game;

use strict;

use Config::General;
use StellarExpanse::Turn;

use base 'Yote::Obj';

#
# Starts the game on turn 0.
#
sub init {
    my $self = shift;

    $self->set_turn( 0 );
    my $first_turn = new StellarExpanse::Turn();
    $self->add_to_turns( $first_turn );

} #init

sub current_turn {
    my $self = shift;
    return $self->get_turns()->[$self->get_turn()];
}

#
# Returns the player object associated with the account, if any.
#
sub find_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    return $self->current_turn()->get_players()->{$acct->get_handle()};
} #find_player

#
# Adds the account to this game, creating a player object for it.
#
sub add_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $players = $self->current_turn()->get_players();
    if( $players->{$acct->get_handle()} ) {
        return { err => "account already added to this game" };
    }
    if( $self->needs_players() ) {
        my $player = new StellarExpanse::Player();
        $player->set_game( $self );
        $player->set_account_root( $acct_root );
        if( $data->{name} ) {
            $player->set_name( $data->{name} );
        }
        $players->{$acct->get_handle()} = $player;
        $acct_root->add_to_my_joined_games( $self );

        if( $self->needs_players() ) { #see if the game is now full
            return { msg => "added to game" };
        } else {
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
    my $players = $self->current_turn()->get_players();
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
    return (! $self->get_active() ) &&
        $self->get_number_players() > keys %{$self->get_turn()->get_players()};
} #needs_players

#
# Called automatically upon the last person joining
#
sub _start {
    my $self = shift;

    $self->set_active( 1 );
    my $players = $self->current_turn()->players();
    for my $player (@$players) {
        my $acct_root = $player->get_account_root();
        $acct_root->remove_from_pending_games( $self );
        $acct_root->add_to_active_games( $self );

	#
	# Set up starting stats
	#
	$player->set_resources( $self->get_starting_resources() );
	$player->set_tech_level( $self->get_starting_tech_level() );

	#
	# Give the player a system group for the empires.
	#
	my $conf = new Config::General( -String => $self->get_flavor()->get_empire_config() );
	
	

    } #each player

    
    
} #_start


1;

__END__
