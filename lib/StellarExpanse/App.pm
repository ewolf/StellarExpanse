package StellarExpanse::App;

use strict;

use StellarExpanse::Flavor;
use StellarExpanse::Game;
use Yote::ObjProvider;

use base 'Yote::AppRoot';

sub init {
    my $self = shift;
    my $flav = $self->new_flavor();
    $flav->set_name( "primary flavor" );
    $self->add_to_flavors( $flav );
}

sub create_game {
    my( $self, $data, $acct_root, $acct ) = @_;

    my $games = $self->get_games({});
    my $game = new StellarExpanse::Game();

    $game->set_app( $self );
    $game->set_name( $data->{name} );
    $game->set_number_players( $data->{number_players} );
    $game->set_created_by( $acct );
    $game->set_flavor( $data->{flavor} );
    my $id = Yote::ObjProvider::get_id( $game );
    $games->{$id} = $game;

    $self->add_to_pending_games( $game );

    return { msg => 'created game', g => $game };
} #create_game

sub new_flavor {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $flav = new StellarExpanse::Flavor();
    $self->add_to_flavors( $flav );
    return $flav;
}

sub available_games {
    my( $self, $data, $acct_root, $acct ) = @_;
    return [ grep { ! $_->find_player($data,$acct_root,$acct) } @{$self->get_pending_games([])}];
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
* submit_orders( game, turn, orders, acct )
* get_orders( game, turn, acct )
* mark_as_ready( game, turn, acct )
* join_game( data, acct )
* get_games( data, acct )
