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
}

sub _init_account {
    my( $self, $acct ) = @_;
    $acct->set_active_games([]);
    $acct->set_pending_games([]);
    $acct->set_active_games([]);
    $acct->set_handle( $acct->get_login()->get_handle() );
    $acct->set_Last_played( undef );
}

sub RESET {
    my( $self, $data, $acct ) = @_;
    die "Access Denied" unless $acct->get_login()->get__is_root();
    $self->set_messageboard( new Yote::Util::MessageBoard() );
    $self->set__account_roots({});
    $self->set__games({});
    $self->set_pending_games([]);
}

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
