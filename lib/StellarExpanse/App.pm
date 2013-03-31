package StellarExpanse::App;

use strict;

use StellarExpanse::Flavor;
use StellarExpanse::Game;
use Yote::ObjProvider;
use Yote::Util::MessageBoard;

use base 'Yote::AppRoot';

sub _init {
    my $self = shift;
    my $flav = $self->new_flavor();
    $flav->set_name( "primary flavor" );
    $self->set_messageboard( new Yote::Util::MessageBoard() );
    $self->set__games({});
    $self->set_pending_games([]);
    $self->set_logged_in([]);
    $self->set_lobby_messages([]);
}

sub _load {
    my $self = shift;
    $self->get_logged_in([]);
    $self->get_lobby_messages([]);
}

sub _init_account {
    my( $self, $acct ) = @_;
    $acct->set_active_games([]);
    $acct->set_pending_games([]);
    $acct->set_handle( $acct->get_login()->get_handle() );
    $acct->set_Last_played( undef );
    $acct->set_last_msg( time() )
}


sub RESET {
    my( $self, $data, $acct ) = @_;
    die "Access Denied" unless $acct->get_login()->get__is_root();
    $self->set_messageboard( new Yote::Util::MessageBoard() );
    $self->set__account_roots({});
    $self->set__games({});
    $self->set_pending_games([]);
}

sub sync_lobby {
    my( $self, $data, $acct ) = @_;
    $self->_register_account( $acct );
} #sync_lobby 

sub _register_account {
    my( $self, $acct ) = @_;
    
    my $now = time();

    my $blocks = $self->get__logged_in_blocks( {} );
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
	    for my $act ( values %{ $blocks->{ $block } } ) {
		$self->add_once_to_logged_in( $act->get_handle() );
	    }
	}
    }
    $five_min_container->{ $acct->{ID} } = $acct;
    $self->add_once_to_logged_in( $acct->get_handle() );

    print STDERR Data::Dumper->Dump(["ADDING REG",$self->get_logged_in()]);

} #_register_account

#
# The updating UI should check the last message time and hold on to it to know if the message board should be refreshed
#
sub message {
    my( $self, $data, $acct ) = @_;
    if( $acct ) {
	my $time = time();
	$self->set_last_msg( $time );
	unshift( @{ $self->get_lobby_messages() },
		 {
		     author  => $acct->get_login()->get_handle(),
		     time    => $time,
		     message => $data 
		 } );

	# pop off messages older than 5 mins if there are more than 50 messages
	if( @{ $self->get_lobby_messages() } > 50 ) {
	    while( @{ $self->get_lobby_messages() } ) {
		last if ( $time - $self->get_messages()->[ 0 ]->{time} ) < 300;
		pop @{$self->get_lobby_messages()};
	    }
	}
	return 1;
    } #if there was an account
    die "Must be logged in to message the lobby";
} #message

sub account {
    my $self = shift;
    my $acct = $self->SUPER::account( @_ );
    
    return $acct;
}

sub load_data {
    my( $self, $data, $acct ) = @_;
    if( $acct ) {
	$self->_register_account( $acct );
	return [
	    $acct->get_active_games(),
	    @{ $acct->get_active_games() },
	    $acct->get_pending_games(),
	    @{ $acct->get_pending_games() },
	    ];
    }
    return undef;
} #load_data

sub create_game {
    my( $self, $data, $acct ) = @_;

    my $games = $self->get__games();
    my $game = new StellarExpanse::Game();

    $game->set_name( $data->{name} );
    $game->set_number_players( $data->{number_players} );
    $game->set_starting_resources( $data->{starting_resources} );
    $game->set_starting_tech_level( $data->{starting_tech_level} );
    $game->set_created_by( $acct );
    $game->set_flavor( $data->{flavor} );
    $game->set_app( $self );
    my $id = Yote::ObjProvider::get_id( $game );
    $games->{$id} = $game;

    $self->add_once_to_pending_games( $game );
    return $game;
} #create_game

sub load_flavors {
    my( $self, $data, $acct ) = @_;

    return [
	@ { $self->get_flavors() },
	map { @{ $_->get_ships() } } @ { $self->get_flavors() },
	];
}

sub new_flavor {
    my( $self, $data, $acct ) = @_;
    my $flav = new StellarExpanse::Flavor();
    $self->add_to_flavors( $flav );
    return $flav;
}

sub available_games {
    my( $self, $data, $acct ) = @_;
    return [ grep { ! $_->_find_player($acct) } @{$self->get_pending_games()}];
} #available_games

1;

__END__


=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Eric Wolf

=cut

Here is where we define the interface that the StellarExpanse UI uses


* create_game( data, acct )
* new_flavor
* available_games( data, acct )
