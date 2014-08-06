package SG::App;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::AppRoot';

use SG::Game;

sub _init {
    my $self = shift;
} #_init

sub _init_account {
    my( $self, $acct ) = @_;
}

sub precache {
    my( $self, $data, $acct ) = @_;
} #precache

sub _load {
    my $self = shift;
}

sub chat {
    my( $self, $data, $acct, $env ) = @_;
    die "Access Error. Must be logged in to chat" unless $acct;
    $self->add_to_chatter(
        new Yote::RootObj( {
            from => $acct->get_handle(),
            msg  => $data } ),
        );
    return '';
} #chat

sub create_game {
    my( $self, $data, $acct, $env ) = @_;
    my $game = new SG::Game( $data );
    $game->set_created_by( $acct );
    $self->add_to_available_games( $game );
    return $game;
} #create_game

sub remove_game {
    my( $self, $game, $acct, $env ) = @_;
    die "Access Error to remove game" unless $acct && $acct->_is( $game->get_created_by() );
    $self->remove_from_available_games( $game );
    my $players = $game->get_players( {} );
    for my $player_acct ( map { $_->get_acct() } values %$players ) {
        $player_acct->_hash_delete( 'joined_games', $game->{ ID } );
    }
    return '';
}

1;

__END__

an app has

 available_games
 active_games
