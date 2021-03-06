package SG::Game;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::Obj';

use SG::Planet;

sub _init {
    my $self = shift;
    $self->_absorb( {
        number_players => 5,
        component_size => {
            armor        => 1, #1 per each 10 non armor size
            battery      => 1,
            blaster      => 1,
            cargo_hold   => 10,
            carrier_hold => 20,
            colony       => 20,
            jump_drive   => 4,
            powerplant   => 3,
            passenger_compartment => 8,
            thrusters    => 1,
            warp         => 2,
        },
        component_mass => {
            armor        => 1, #1 per each 10 non armor size
            battery      => 1,
            blaster      => 1,
            cargo_hold   => 3,
            carrier_hold => 7,
            colony       => 10,
            jump_drive   => 10,
            passenger_compartment => 6,
            powerplant   => 3,
            thrusters    => 1,
            warp         => 2,
        },
        component_cost => { #per unit
            armor        => 1,
            battery      => 2,
            blaster      => 2,
            cargo_hold   => 2,
            carrier_hold => 10,
            colony       => 40,
            jump_drive   => 10,
            passenger_compartment => 8,
            powerplant   => 10,
            thrusters    => 2,
            warp         => 4,
        },
        development_costs => {
            # in population turns per level times 1 + current level
            factory => 10,
            mine    => 10,
            depot   => 5,
            colony  => 20,
        },
        resources => [qw( ore fastium shrinkium growium blastium turtlite tofunite featheride organium plastica )],
                    } );
    $self->set_components( [ keys %{$self->get_component_cost()} ] );
} #_init

#
# Return the player associated with the account.
#
sub player {
    my( $self, $data, $acct, $env ) = @_;
    return $self->_hash_fetch( 'players', $acct->get_handle() );
} #player

sub ready_player {  #TODO - take this sub away entirely
    my( $self, $player, $acct, $env ) = @_;
    my $players = $self->get_players();
    die "access error" unless $player && $player->_is( $players->{ $acct->get_handle() } );
    $player->set_is_ready( 1 );
    
#    if( 0 == grep { ! $_->get_is_ready() } values %$players ) {
        # if no players are unready
        $self->_take_turn();
#    }
    
} #ready_player

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
                                  marketplace => { map { 
                                      $_ => new Yote::Obj(
                                          {
                                              buy_cost => $_ eq 'ore' ? 10 : 50,
                                              sell_cost => $_ eq 'ore' ? 2 : 10
                                          } ) }
                                                   @{$self->get_resources()} },
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

    # set up sectors and systems
    # home systems are 5 tiles.
    # master system is 1 tile
    # regular systems are 5 tiles

  #    *   *
  #    |\ /|
  # *--0-0-0---*
  #  \ |\|/|  /
  #   \| O | /
  #    |/ \|/
  #    0---0
  #     \ /
  #      *
  #  * - player sector
  #  0 - other sector
  #  O - master sector

    my $player_sectors = [];
    my $other_sectors = [];
    for( 1..5 ) {
        push @$player_sectors, new Yote::Obj;
        push @$other_sectors, new Yote::Obj;
    }
    my $master_sector = new Yote::Obj;

    my @players = values %{ $self->get_players({}) };

    for( 0..4 ) {

        my $os = $other_sectors->[ $_ ];

        my $ps1 = $player_sectors->[ $_ ];
        my $ps2 = $player_sectors->[ ($_==0 ? 4 : $_-1) ];

        $os->add_to_connections( $ps1, $ps2, $master_sector );
        $master_sector->add_to_connections( $os );
        $ps1->add_to_connections( $os );
        $ps2->add_to_connections( $os );

        # add one system for now for the player
        my $start_system = new Yote::Obj( {
            name   => 'start system',
            sector => $ps1,
                                              } );

        my $player = $players[ $_ ];


        my $other_system = new Yote::Obj;
        $ps1->add_to_systems( $start_system, $other_system );

        $start_system->add_to_connections( $other_system );
        $other_system->add_to_connections( $start_system );

        my $homeworld = new SG::Planet();
        $homeworld->_setup( $self, {
            name => 'homeworld',
            system => $start_system,
            abundance => 30,
            max_pop => 10,
                            } );
        $homeworld->get_mines()->{ ore }->set_rate( 1 ); 
        $homeworld->get_mines()->{ fastium } = new Yote::Obj( 
            { 
                rate              => 0,
                workers_expanding => 0,
                workers_mining    => 0,
                planet            => $homeworld,
            } );
        $homeworld->get_depot()->set_capacity( 20 );
        $homeworld->get_factory()->set_build_rate( 1 );
        my $dist = $homeworld->get_resource_distribution();
        $dist->{ ore } = 0.8;
        $dist->{ fastium } = 0.2;
        $homeworld->get_colony()->set_population( 3 );
        $homeworld->_take_control( $player );

        my $freighter_recipe = new Yote::Obj( {
            name => 'freighter',
            composition => {
                # special resources go here
            },
            components => {
                thrusters      => 1,
                passenger_hold => 1,
                cargo_hold     => 1,
            },
                                              } );
        
        my $colony_recipe = new Yote::Obj( {
            name => 'colony ship',
            composition => {
                # special resources go here
            },
            components => {
                warp      => 1,
                thrusters => 1,
                colony    => 1,
            },
                                           } );
            
        $self->calculate_recipe_stats( $freighter_recipe );
        $self->calculate_recipe_stats( $colony_recipe );


        $player->_absorb( {
            ships     => [],
            sectors   => [ $ps1 ],
            systems   => [ $start_system ],
            planets   => [ $homeworld ],
            total_pop => 3,
            money     => 10,
            recipes   => [ $freighter_recipe, $colony_recipe ],
                          } ) if $player;

        my $otherworld = new SG::Planet();
        $otherworld->_setup( $self, { name => 'other world' } );
        $otherworld->set_name( 'other world' );

        $start_system->add_to_planets( $homeworld, $otherworld );

        # TODO - planetary calculations to find del theta ( and possibly del others 
        #list of items at that location
        $start_system->set_items( [   # [ radius, theta radians, thing ]
                                      [ 10, .4, $homeworld ],
                                      [ 14, .4, $otherworld ],
                                  ] );
        $start_system->set_radius( 100 );
        
        # for home systems, they have a fixed amount of materials in random proportions
        # the planets in the system are somewhat random, too

    } # 0 - 4

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
sub calculate_recipe_stats {
    my( $self, $recipe ) = @_;

    my $sizes          = $self->get_component_size();
    my $masses         = $self->get_component_mass();
    my $resource_costs = $self->get_component_cost();

    my $stats = $recipe->get_stats( {} );
    my $composition = $recipe->get_composition( {} );

    # armor is boolean. If you have armor, the weight for it is calculated
    my( $size, $mass, $resource_cost );
    my $components = $recipe->get_components();
    for my $comp ( keys %$components ) {
        if( $comp ne 'armor' ) {
            # armor is special
            $mass  += $masses->{ $comp } * $components->{ $comp };
            $size  += $sizes->{ $comp } * $components->{ $comp };
            $resource_cost += $resource_costs->{ $comp };
        }
        
    }
    if( $components->{ armor } ) {
        my $armorsize = 1 + int( $size / 2 );
        $resource_cost += $armorsize * $components->{ armor };
        $armorsize +=  2 * $components->{ armor };
        $size += $armorsize;
        $mass += $armorsize * $masses->{ armor };
        $stats->{ armor } = $components->{ armor };
    }

    my $tofu_boost = 1 + $composition->{ tofunite };
    my $size_diff = $tofu_boost * ( $composition->{ growium } - $composition->{ shrinkium } );

    $stats->{ blast_power }    = sprintf( "%d.2", $components->{ blaster } + $tofu_boost * $composition->{ blastium } );
    $stats->{ cargo_capacity } = $components->{ cargo_hold } * $sizes->{ cargo_hold } +  $size_diff;
    $stats->{ colonize_size }  = $components->{ colony } + $tofu_boost * $composition->{ organium };

    $stats->{ passengers } = $components->{ passenger_compartment } + $tofu_boost * $composition->{ organium };

    my $build_size = $size + $size_diff;
    $build_size = 1 if $build_size < 1;

    $recipe->set_size( $build_size );
    $stats->{ size } = $build_size;

    # the ore is calculated rather than given
    $composition->{ ore } = $resource_cost; 

    # mass goes here, along with warp and jump ratings
    $mass -= $tofu_boost * $composition->{ featheride };
    $mass = 1 if $mass < 1;
    $stats->{ mass } = $mass;
    $stats->{ thrust_rating } = sprintf( "%d.2", (10*$components->{ thrusters }) / ( 1 + $mass ));
    $stats->{ warp_rating } = sprintf( "%d.2",  (10*$components->{ warp }) / ( 1 + $mass ) );
    $stats->{ jump_rating } = sprintf( "%d.2", (10*$components->{ jump_drive }) / ( 1 + $size ) );
                       
    my $build_rate = $build_size - $composition->{ plastica };

    # calculate what happens due to the addons.

    my $total_material_cost = 0;
    for my $comp (keys %$composition) {
        $total_material_cost += $composition->{$comp};
    }
    $recipe->set_total_material_cost( $total_material_cost );
    

} #calculate_recipe_stats


1;

__END__

number_players
players - { acctid -> player }
is_active


#--- sector ----

connections - [ list of sectors this connects with ]
systems     - internal systems

#---- system ----

name
connections - [ list of systems this connects with ]
planets - ( planets and others )

#---- planet ( location ) ----

max_pop   - max population size ( from 1-100 )
resources - hash of resource type --> abundance
colony  - a planet may have one colony
mines    - a planet may have one mine per matierial type
factory - a planet may have one factory
depot    - a planet has one big resources depot
abundance - how much can be produced per turn of this planet (multiple of 10)
resource_distribution - hash of resource -> count. the sum of all resources must equal 10.
ships - list of ship objects here

(? should there be a resource depot on the planet? I think yes ?)

#---- player -----

sectors - list of sectors this player has a presence in
systems - list of systems controlled
resources - hash of resource type -> amount
recipes -
ships - list of ships


#---- colony -----

name        -
owner       - player
population  - current population

It takes 10 worker-turns to grow a colony by 1
A colony can create a factory and mines.
A colony ship can create a factory

#---- factory -----

build_rate - how many units of resources can be used per turn to build a ship.

#---- recipe

compositition - hash of resource -> amount
components - hash of componennt -> number


#---- ship components

blaster      - blasts                         - 1 size unit - 2 resource
armor        - absorbs damage                 - 1 per non armor size - 1 resource
warp engine  - gives speed                    - 2 size unit - 4 resource
jump drive   - jumps a given weight.          - 4 size unit - 10 resources
passenger compartment - holds a population    - 8 size per unit - 8 resources
carrier hold - carries other ships            - 10 size per unit - 4 resource
cargo hold   - just for cargo                 - 1 size per unit - 2 resource
colony       - ability to make a new colony   - 20 size per unit - 40 resource

long range jump?
conventional drive?
shield?

#---- ship ----

composition - a hash of resource to amount. The sum of the amounts must add up to 10. The resources affect all the components of the ship.

armor       -
blast_power -
carry_capacity  - in size units
colonize_size - size of colony created. Upon creation, the 'ship' turns into the colony
jump_rating  - how many size * mass units this can jump ( alternatively, how much power required )
mass        -
passengers  -
size        -
warp_rating - distance units per mass units this can move in a turn

# resources :

ore        - standard vanilla ore
fastium    - increases speed
shrinkium  - decreases size ( useful for carrying a punch in a carrier )
growium    - increase size ( useful for *being* a carrier )
blastium   - increases blaster power
turtleite  - increases defensive power
tofunite   - doubles the effectiveness of effective ores up to its weight
featheride - decreases mass
organium   - allows more population to be in a colony past its size or a ship carrying passengers
plastica   - decreases construction speed

#---- mine -----

rate - in chunks of 1 decaunits : how much can this mine up to the planets
                         abundance.  needs one population per chunk
  a mine *is* needed to gather resources

,?? mineral composition

#---------------- overall -------------------

player can build a colony which has a certain amount of population
(? You get one income unit per population in a colony ?)

A colony must be built on varying degrees of habitible land. A planet ( location ) will have a max
population that it can support.
There is a 10-100 scale of how habitible it is. The colony will
have that much population. All colonies cost the same. You can put a colony in an asteroid belt and
it will have a minimum of 10 population.
Colonies are built as ships. They can be carried in other ships, or even given propulsion of their own.

A home system will have 100 units of population randomly distributed in its planets but be concentrated
in the home world ( which will have at least half ). Any place will have pop in increments of 10.

Resource units are used to calculate the cost of ships per turn. Ships are designed with recipes. The player
can adjust the composition of the components of the ships' recipes.

The home system will have 100 units of resource allocation. (The most common will be ore.).  This production
will be spread througough the planets in the system with a minimum in the home planet. ( maybe min amount ore,
then a min amount of a random resource then the rest is distributed normally ).

The player starts with 10 RUs of every type and starts with a 40 colony with a mine and a factory.

(? The player collects so many resource units per turn. The marketplace also collects a certain number of units.
The player can sell to and buy from the marketplace. Thus, the cost of the ship is free as long as there are
resources of the appropriate type for the player.  Any overflow is supplanted by the marketplace for a cost.
 Resource units are automatically collected by the player and the marketplace due to abstracted out small mines.
These are collected only from planets with a colony ( colonies of size 1 are bases, like a mining base ). A planet
will have a unit resource rating for each of the different resource types. ?)

Each planet has a colony slot, a mine slot and a factory slot.
If a planet has a colony, it can build a mine and a factory (one or the other but not both) and it takes
10 population-turns but doesnt consume any resources. This is for playability and simplicity.

#<--- important, check all this in
