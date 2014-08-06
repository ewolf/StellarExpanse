package SG::Factory;

use strict;
use warnings;
no warnings 'uninitialized';

use base 'Yote::Obj';

use SG::Ship;

sub queue_build {
    my( $self, $recipe, $acct, $env ) = @_;    

    my $player = $self->player( undef, $acct );

    die "access error" unless $player && $player->_is( $self->get_owner() );

    $self->add_to_build_queue( new SG::Ship( { 
        completed => {}, # resource -> built amount for building
        recipe => $recipe,
                                               } ) );

} # queue_build


1;

__END__
