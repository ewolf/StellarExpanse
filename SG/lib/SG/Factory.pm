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

    my $player = $self->get_game()->player( undef, $acct );

    die "access error" unless $player && $player->_is( $self->get_owner() );

    my $ship = new SG::Ship( { 
        completed => new Yote::Obj(), # resource -> built amount for building
        recipe => $recipe,  #TODO - collate the build queue so that one ship will just be n times there
                             } );

    $self->add_to_build_queue( $ship );

    my $g = "set_$ship->{ID}";
    $self->get_build_assignments()->$g( 0 );
    $self->add_to_building( $ship );

} # queue_build

sub _produce {
    my $self = shift;
    
    my $planet = $self->get_planet();
    my $player = $self->get_owner();
    my $game   = $player->get_game();
    my $marketplace = $game->get_marketplace();

    my $queue = $self->get_build_queue();
    my $assignments = $self->get_build_assignments();

    my $depos = $planet->get_resource_depos();

    print STDERR Data::Dumper->Dump([$queue,"Q"]);

    for my $ship ( @$queue ) {
        my $workers = $assignments->_get( $ship->{ID} );
        next unless $workers;
        my $recipe = $ship->get_recipe();
        my $done   = $ship->get_completed();
        my $composition = $recipe->get_composition();

        my $money = $player->get_money();

        my $to_build = scalar( grep { ($composition->{$_} - $done->_get( $_ ) ) > 0 } 
                               values %$composition );
        while( $to_build && $workers && $money ) { 
            # TODO - sort the list on cheapness once the economy is once again variable
            for my $res ( grep { ($composition->{$_} - $done->_get( $_ )) > 0 } 
                          values %$composition )
            {
                my $depot   = $depos->{ $res };
                my $avail_from_depot = $depot->get_contents();
                
                if( $avail_from_depot ) {
                    $to_build--;
                    $done->_set( $res, $done->_get( $res ) + 1 );
                } else {
                    my $cost = $marketplace->{ $res }->get_buy_cost();
                    if( $money >= $cost ) {
                        $money -= $cost;
                        $to_build--;
                        $done->_set( $res, $done->_get( $res ) + 1 );
                    }
                }
                last if $workers == 0 || $to_build == 0 || $money == 0;
            } #each resource
        }
        $player->set_money( $money );
        
        # if the ship is done
        if( $to_build == 0 ) { 
            #remove from assignments
            $assignments->_set( $ship->{ID}, undef );
            $self->remove_from_build_queue( $ship );
            $self->get_build_assignments()->_set( $ship->{ID}, undef );

            #add to planet and active ships
            $planet->add_to_ships( $ship );
            $player->add_to_ships( $ship );
        }
        
    } #each assigned build

} #_produce

1;

__END__
