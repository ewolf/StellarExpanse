package SG::Planet;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::RootObj';

use SG::Factory;


sub _setup {
    my( $self, $game, $data ) = @_;

    my $resources = $game->get_resources();

    $self->_absorb(
        {
            abundance => 5, #how much can be produced per turn of this planet

            colony  => new Yote::Obj(  # each planet has a colony slot when created
                                       {
                                           name              => 'colony',
                                           planet            => $self,
                                           population        => 0,
                                           workers_expanding => 0,
                                       } ),



            factory => new SG::Factory(  # each planet has a factory slot when created
                                         {
                                             build_rate            => 1,
                                             workers_expanding     => 0,
                                             workers_manufacturing => 0,
                                             build_queue           => [],
                                             planet                => $self,
                                         } ),

            game => $game,

            max_pop => 5,

            name    => "a planet",

            owner => undef,
                    
            depot => new Yote::Obj( {
                capacity          => 0,
                content_count     => 0,
                workers_expanding => 0,
                contents          => {},
                                            } ),
            
            resource_distribution => { #these all add up to 1. # TODO : on creation, a randomizer for stuff...maybe
                map {
                    $_ => $_ eq 'ore' ? 1 : 0,
                } @$resources,
            },

            ships => [],
        } );
    $self->_absorb( $data ) if $data;

    $self->_absorb( {
            mines => {
                map { 
                    $_ => new Yote::Obj( {
                        rate              => 0,
                        workers_expanding => 0,
                        workers_mining    => 0,
                        planet            => $self,
                                         } ),
                } keys %{$self->get_resource_distribution()},
            } } );

} #_setup

sub _take_control {
    my( $self, $player ) = @_;
    $self->set_owner( $player );
    $self->get_colony()->set_owner( $player );
    $self->get_factory()->set_owner( $player );
    $self->get_colony()->set_owner( $player );
} #_take_control

1;

__END__
