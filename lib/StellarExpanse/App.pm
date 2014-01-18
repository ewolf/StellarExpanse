package StellarExpanse::App;

use strict;

use StellarExpanse::Comm;
use StellarExpanse::Flavor;
use StellarExpanse::Game;

use Yote::ObjProvider;

use base 'Yote::AppRoot';

sub _init {
    my $self = shift;
    $self->SUPER::_init();

    my $flav = $self->_new_flavor();
    $flav->set_name( "primary flavor" );
    $self->add_to_flavors( $flav );

    $self->set_logged_in( [] );
    $self->set__logged_in_blocks( {} );    

    $self->set_messageboard( new Yote::Obj( { chatter => [] } ) );

    $self->set_pending_games( [] );

    $self->set_available_games( [] );

} #_init


#
# When accounts are created here. The comm hashes actt id to converstaion objects.
#
sub _init_account {
    my( $self, $acct ) = @_;
    $acct->set_comm( new StellarExpanse::Comm( { __creator => $acct } ) );
    $acct->set_pending_games([]);
    $acct->set_active_games([]);
    $acct->set_last_msg( time() );
    $acct->set_app( $self );
}

#
# Registers the account as taken an activity in the lobby.
#
sub sync_lobby {
    my( $self, $data, $acct ) = @_;
    $self->_register_account( $acct );
} #sync_lobby

sub sync_changed {
    my( $self, $data, $acct ) = @_;
}

sub precache {
    my( $self, $data, $acct ) = @_;
    my $ret = [ $self->get_pending_games(),
                @{$self->get_pending_games()},
                $self->get_messageboard(),
                @{$self->get_messageboard()->get_chatter()},
                $self->get_logged_in(),
                @{$self->get_logged_in()},
        ];
    if( $acct ) { 
        push @$ret, $acct->get_active_games(), @{$acct->get_active_games()}, $acct->get_pending_games(), @{$acct->get_pending_games()}, $acct->get_comm();
        if( $acct->is_root() ) {
            push @$ret, map { $_, $_->precache() } @{$self->get_flavors()};
        }
    }
    return $ret;
} #precache

#
# Keeps tracked of 'who is logged in'. People are on
# the list of those logged in in the last 5 minutes.
#
sub _register_account {
    my( $self, $acct ) = @_;
    
    my $now = time();

    my $blocks = $self->get__logged_in_blocks();
    my $five_min_block = int( $now / 300 );
    my $five_min_container = $blocks->{ $five_min_block };
    unless( $five_min_container ) {
        $five_min_container = {};
        $blocks->{ $five_min_block } = $five_min_container;
        # check here to remove containers older than 10 mins
        my $too_old = $five_min_block - 1;
        for my $block ( keys %$blocks ) {
            if( $block < $too_old ) {
                delete $blocks->{ $block };
            }
        }
        # refresh get_logged_in list
        $self->set_logged_in( [] );
        for my $block ( keys %$blocks ) {
            for my $acts ( values %{ $blocks->{ $block } } ) {
                for my $act (@$acts) {
                    $self->add_once_to_logged_in( $act );
                }
            }
        }
    }
    $five_min_container->{ $acct->{ID} } = $acct;
    $self->add_once_to_logged_in( $acct );

} #_register_account

# ----  GAMES -------

sub create_game {
    my( $self, $data, $acct ) = @_;

    die "Access Error" unless $acct;

    my $game = new StellarExpanse::Game();

    $game->set_name( $data->{name} );
    $game->set_number_players( $data->{number_players} );
    $game->set_starting_resources( $data->{starting_resources} );
    $game->set_starting_tech_level( $data->{starting_tech_level} );
    $game->set_created_by( $acct );
    $game->set_flavor( $data->{flavor} );
    $game->set_app( $self );
    $game->set_needs_players( $data->{number_players} );

    $self->add_to_available_games( $game );
    return $game;
} #create_game

sub remove_game {
    my( $self, $game, $acct ) = @_;

    if( $acct && $acct->_is( $game->get_created_by() ) ) {
        my $players = $game->_current_turn()->get_players({});
        for my $player ( values %$players ) {
            $player->get_account()->remove_all_from_pending_games( $game );
            $player->get_account()->remove_all_from_active_games( $game );
        }
        $self->remove_all_from_available_games( $game );
        
        return "Removed";
    }
    die "Unable to remove game";
    
} #remove_game

# ----  FLAVS -------

sub new_flavor {
    my( $self, $data, $acct ) = @_;
    die "Access Error" unless $acct->is_root();
    return $self->_new_flavor($data);
}

sub _new_flavor {
    my( $self, $data ) = @_;
    my $flav = new StellarExpanse::Flavor( $data );
    return $flav;
}

1;

__END__

This App hosts Stellar Expanse games and provides accounts to play
those games and allows users to chat and send messages to each other.

Data :
   flavors   - list of flavor objects
   logged_in - a list of accounts that have been active in the last 10 minutes
       _logged_in_blocks - a hash of time ( normalized to 5 min chunks since the epoch ) 
                                to a list of accounts that have been active in that chunk of time. Used to populated logged_in list
   messageboard - an object used for players to chat in the lobby
   pending_games - a list of games not yet started


Account :
   

=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Eric Wolf

=cut

Here is where we define the interface that the StellarExpanse UI uses


* create_game( data, acct )
* new_flavor
* available_games( data, acct )
