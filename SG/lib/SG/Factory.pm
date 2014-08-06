package SG::Factory;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::Obj';

use SG::Ship;

sub _init {
    my $self = shift;
    $self->set_build_assignments( new Yote::Obj() );  #workers --> queued builds
}

sub queue_build {
    my( $self, $recipe, $acct, $env ) = @_;

    my $owner = $self->get_owner();

    die "access error" unless $owner && $owner->get_acct()->_is( $acct );

    my $composition = $recipe->get_composition();
    my $total_cost = 0;
    for my $comp (keys %$composition) {
        $total_cost += $composition->{$comp};
    }

    my $ship = new SG::Ship( {
        completed   => new Yote::Obj(), # resource -> built amount for building
        to_complete => $total_cost,
        materials_completed => 0,
        recipe      => $recipe,  #TODO - collate the build queue so that one ship will just be n times there
                             } );

    $self->add_to_build_queue( $ship );

    my $g = "set_$ship->{ID}";
    $self->get_build_assignments()->$g( 0 );
    $self->add_to_building( $ship );

} # queue_build

sub _produce {
    my $self = shift;

    my $planet = $self->get_planet();
    my $owner = $self->get_owner();
    return unless $owner; #has to be controlled to produce

    my $marketplace = $owner->get_marketplace();

    my $queue = $self->get_build_queue();
    my $assignments = $self->get_build_assignments();

    my $depot = $planet->get_depot();

    for my $ship ( @$queue ) {
        my $workers = $assignments->_get( $ship->{ID} );
        next unless $workers;
        my $recipe = $ship->get_recipe();
        my $done   = $ship->get_completed();
        my $composition = $recipe->get_composition();

        my $money = $owner->get_money();

        my $to_complete = $ship->get_to_complete();
        my $mat_completed = $ship->get_materials_completed();

        while( $to_complete && $workers ) {
            # TODO - sort the list on cheapness once the economy is once again variable
            my $did = 0;
            for my $res ( grep { ($composition->{$_} - $done->_get( $_ )) > 0 }
                          keys %$composition )
            {
                my $avail_from_depot = $depot->get_contents()->{ $res };
                if( $avail_from_depot ) {
                    $to_complete--;
                    $mat_completed++;
                    $workers--;
                    $done->_set( $res, $done->_get( $res ) + 1 );
                    $depot->get_contents()->{ $res } = $avail_from_depot - 1;
                    $did++;
                } else {
                    my $cost = $marketplace->{ $res }->get_buy_cost();
                    if( $money >= $cost ) {
                        $money -= $cost;
                        $to_complete--;
                        $workers--;
                        $did++;
                        $mat_completed++;
                        $done->_set( $res, $done->_get( $res ) + 1 );
                    }
                }
            } #each resource
            last if $workers == 0 || $to_complete == 0 || $money == 0;
            last unless $did;
        }
        $owner->set_money( $money );
        $ship->set_materials_completed( $mat_completed );

        $ship->set_to_complete( $to_complete );

        # if the ship is done
        if( $to_complete == 0 ) {
            #remove from assignments
            $assignments->_set( $ship->{ID}, undef );
            $self->remove_from_build_queue( $ship );
            $self->get_build_assignments()->_set( $ship->{ID}, undef );

            #add to planet and active ships
            $planet->add_to_ships( $ship );
            $owner->add_to_ships( $ship );
        }

    } #each assigned build

} #_produce

1;

__END__
