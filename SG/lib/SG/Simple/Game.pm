package SG::Simple::Game;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::Obj';

use SG::Planet;

sub _init {
    my $self = shift;
    $self->set_number_players( 1 );
} #_init

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

    # add the account to the game ( TODO - decide if this should be a RootObj for security )
    my $player = new Yote::Obj( { name => $acct->get_handle(), 
                                  acct => $acct, 
                                  game => $self,
                                } );
    $players->{ $acct->get_handle() } = $player;


    $acct->_hash_insert( 'joined_games', $self->{ID}, $self );

    # check if the game is now starting
    if( scalar( keys %$players ) == $self->get_number_players() ) {
        $self->_activate();
    }

    return $player;
} #add_player

sub _activate {
    my $self = shift;
    $self->set_is_active( 1 );

    # create planets for the system

    # for simple, they are all in a line
    $self->set_planets( [
                            new Yote::Obj( {
                                name => 'Alpha Nowhere',
                                x => 0,
                            } ),
                            new Yote::Obj( {
                                name => 'Beta Nowhere',
                                x => 10,
                            } ),
                            new Yote::Obj( {
                                name => 'Gamma Nowhere',
                                x => 60,
                            } ),
                            new Yote::Obj( {
                                name => 'Epsilon Nowhere',
                                x => 90,
                            } ),
                        ] );


} #_activate

# workers expanding a planet feature
sub _expand {
    my( $self, $obj, $isa, $field, $max ) = @_;

    my $dev_costs = $self->get_development_costs();

    my $workers  = $obj->get_workers_expanding();
    my $progress = $obj->get_expansion_progress();

    my $val   = $obj->_get( $field );
    $progress += $workers;
    while( $progress >= $dev_costs->{ $isa } && ( ! defined( $max ) || $val < $max ) ) {
        $progress -= $dev_costs->{ $isa };
        $val++;
    }
    $obj->_set( $field, $val );
    $obj->set_expansion_progress( $progress );
    
} #_expand

sub _take_turn {
    my $self = shift;
    
    my $players = $self->get_players();

    # turn order - fire, move, build

    # fire

    # move

    # build ( accept factory orders )


    my $ship_part_costs = $self->get_component_cost();

    for my $player ( values %$players ) {
        for my $planet ( @{ $player->get_planets() } ) {
            my $mines = $planet->get_mines();
            my $depot = $planet->get_depot();
            my $dists = $planet->get_resource_distribution();

            # checking for depot expansion
            $self->_expand( $depot, 'depot', 'capacity' );

            # 
            # mine resources and check for mine and depot expansions.
            # TODO : mine the most expensive things first
            #
            for my $res (keys %$dists ) {
                my $mine    = $mines->{ $res };
                my $dist    = $dists->{ $res } || 0;

                # setting resources in depot
                my $workers = $mine->get_workers_mining();
                my $depot_contents = $depot->get_contents();
                my $new_content_size = $workers + $depot_contents->{ $res };
                my $cap = $depot->get_capacity();
                $depot_contents->{ $res } = $new_content_size > $cap ? $cap : $new_content_size;

                # checking for mine expansion
                $self->_expand( $mine, 'mine', 'rate', $planet->get_abundance() * $dist );

            }

            my $fact = $planet->get_factory();
            $fact->_produce();

            # check for factory expansion
            $self->_expand( $fact, 'factory', 'build_rate' );

            # check for settlement expansion
            $self->_expand( $planet->get_colony(), 'colony', 'population', $planet->get_max_pop() );

        } #each planet

    } #loop through each player

} #_take_turn

# calc weight, size, etc

1;

__END__

number_players
players - { acctid -> player }
is_active

