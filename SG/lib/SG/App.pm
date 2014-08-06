package SG::App;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::AppRoot';

use Yote::Root;

use SG::Game;


sub _init {
    my $self = shift;
    my $sg = $self->_update_cron();
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

sub add_player {
    my( $self, $game, $acct, $env ) = @_;
    $game->add_player( undef, $acct, $env );
    if( $game->get_is_ready( 1 ) ) {
        $self->remove_from_available_games( $game );
        $self->add_to_active_games( $game );
    }
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

#makes sure the cron is checking turns every minute or so
sub _update_cron {
    my $self = shift;

    my $sg = $self->get_cron_entry();

    unless( $sg ) {
        # check to see if this is in the cron already. Remove it if it is
        my $root = Yote::Root::fetch_root;
        my $cron = $root->_cron();

        my( $old_cron ) = grep { $_->get_name() eq 'SG' } @{$cron->get_entries()};
        if( $old_cron ) {
            $cron->remove_from_entries( $old_cron );
        }
        
        $sg = new Yote::RootObj( {
            name    => 'SG',
            enabled => 1,
            script  => 'use Yote::Root; use SG::App; my $r = Yote::Root::fetch_root(); my $a = $r->fetch_app_by_class( "SG::App" ); if( $a ) { print STDERR " SG :: checking turns\n"; $a->_check_turns; print STDERR " SG :: checking turns done\n";  } else { print STDERR "Could not find SG::App\n" };',
            repeats => [new Yote::Obj( { repeat_interval => 1, repeat_infinite => 1, repeat_times => 0 } ) ],
                                    } );
        $cron->add_to_entries( $sg );
        $self->set_cron_entry( $sg );
    }
    $sg->set_enabled( 1 );
    return $sg;
} #update_cron

#checks the turns of all active games
sub _check_turns {
    my $self = shift;
    
    my $games = $self->get_active_games();
    for my $game (@$games) {
        $game->_take_turn;
    }

} #_check_turns

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
    $self->remove_from_active_games( $game );
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
