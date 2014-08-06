package SG::Game;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::Obj';
use base 'Yote::UserObj';

sub _init {
    my $self = shift;
    $self->set_number_players( 5 );
}

#
# Return the player associated with the account.
#
sub player {
    my( $self, $data, $acct, $env ) = @_;
    return $self->_hash_fetch( 'players', $acct->get_handle() );
} #player

sub add_player {
    my( $self, $data, $acct, $env ) = @_;
    die "Must be logged in to add player" unless $acct;
    my $players = $self->get_players({});
    die "Already joined game " . $self->get_name() if $players->{ $acct->get_handle() };
    die "Game " . $self->get_name() . " is full" if scalar( keys %$players ) == $self->get_number_players();

    # add the account to the game
    my $player = new Yote::UserObj( { name => $acct->get_handle(), acct => $acct } );
    $players->{ $acct->get_handle() } = $player;

    $acct->_hash_insert( 'joined_games', $self->{ID}, $self );

    # check if the game is now starting
    if( scalar( keys %$players ) == $self->get_number_players() ) {
        $self->_activate();
        $self->remove_from_available_games( $self );
    }

    return $player;
} #add_player

sub _activate {
    my $self = shift;
    $self->set_is_active( 1 );

    # set up sectors and systems
    # home systems are 5 tiles.
    # master system is 1 tile
    # regular systems are 5 tiles
    
  #    *   *
  #    |\ /|
  # *--0 0 0--*
  #  \   |   /
  #   \  O  /
  #   | / \ |
  #   0    0
  #    \  /
  #     *
  #  * - player sector
  #  0 - other sector
  #  O - master sector

    my $player_sectors = [];
    my $other_sectors = [];
    for( 1..5 ) {
        push @$player_sectors, new Yote::RootObj;
        push @$other_sectors, new Yote::RootObj;
    }
    my $master_sector = new Yote::RootObj;

    my @players = values %{ $self->get_players({}) };

    for( 0..4 ) {
        
        my $os = $other_sectors->[ $_ ];
        
        my $ps1 = $player_sectors->[ $_ ];
        my $ps2 = $player_sectors->[ $_==0 ? 4 : $_+1 ];

        $players[ $_ ].add_to_sectors( $ps1 );

        $os->add_to_connections( $ps1, $ps2, $master_sector );
        $master_sector->add_to_connections( $os );
        $ps1->add_to_connections( $os );
        $ps2->add_to_connections( $os );

        # add one system for now for the player
        my $start_system = new Yote::RootObj( { name => 'start system' } );
        $players[ $_ ].add_to_systems( $start_system );

        my $other_system = new Yote::RootObj;
        $ps1->add_to_systems( $start_system, $other_system );
        
        $start_system->add_to_connections( $other_system );
        $other_system->add_to_connections( $start_system );

        my $homeworld = new Yote::RootObj;
        my $otherworld = new Yote::RootObj;
        $start_system->add_to_locations( $homeworld, $otherworld );

        # for home systems, they have a fixed amount of materials in random proportions
        # the planets in the system are somewhat random, too
        
        
    } # 0 - 4

} #_activate

1;

__END__

number_players
players - { acctid -> player }
is_active


#--- sector ----

connections - [ list of sectors this connects with ]

systems - internal systems

#---- system ----

connectoins - [ list of systems this connects with ]

locations - ( planets and others )

?? mineral composition

#---------------- overall -------------------

player can build a colony which has a certain amount of population ( say max 10 per colony ).
You get one income unit per population in a colony.
A colony must be built on arable land. There is a 1-10 scale of how arable it is. The colony will
have that much population. All colonies cost the same. You can put a colony in an asteroid belt and 
it will have a minimum of 1 population.

#<--- important, check all this in

