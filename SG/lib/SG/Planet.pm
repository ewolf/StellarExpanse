package SG::Planet;

use strict;
use warnings;
no warnings 'unitialized';

use base 'Yote::RootObj';

sub _init {
    my $self = shift;
    $self->_absorb(
        {
            name    => "planet",
            max_pop => 10,
            factory => new Yote::RootObj(  # each planet has a factory slot when created
                                           { 
                                               build_rate            => 0,  # in units of multiples of 10. 0 indicates no factory
                                               workers_expanding     => 0,
                                               workers_manufacturing => 0,
                                           } ),
            colony  => new Yote::RootObj(  # each planet has a colony slot when created
                                           {
                                               name           => 'colony',
                                               owner          => undef,
                                               population     => 0,
                                               max_population => 0,
                                           } ),
            mine   => new Yote::RootObj(   # each planet has a mine slot when created
                                           {
                                               rate              => 1, #deca units. 0 indicates no mine
                                               workers_expanding => 0,
                                               workers_mining    => 0,
                                           } ),
            abundance => 10, #how much can be produced per turn of this planet, in multiples of 10
            resource_distribution => { #these all add up to 10
                ore     => 10,  
            },
        } );
} #_init

1;

__END__
