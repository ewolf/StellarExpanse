package StellarExpanse::Sector;

use strict;

use base 'Yote::Obj';

sub init {
    my $self = shift;
    $self->set_ships([]);
}

#
# Notifies any ships or system owners of an occurance.
#
sub _notify {
    my( $self, $msg ) = @_;
    my $owner = $self->get_owner();
    if( $owner ) {
        $owner->_notify( $msg );
    }
    my $ships = $self->get_ships();
    for my $ship (@$ships) {
        $ship->_notify( $msg );
    }
    
} #_notify

#
#  Used in setup
#
sub _link_sectors {
    my( $self, $other ) = @_;
    die "Can only link a sector to a sector" unless $other->isa( 'StellarExpanse::Sector' );
    my $Alinks = $self->get_links({});
    my $Blinks = $other->get_links({});
    $Alinks->{$other->{ID}} = $other;
    $Blinks->{$self->{ID}} = $self;
    return undef;
}

# takes an id of a sectors and returns true if the two link together.
sub _valid_link {
    my( $self, $id ) = @_;
    my $links = $self->get_links();
    if( $links->{$id} ) {
        my $olinks = $links->{$id}->get_links();
        return $olinks->{$self->{ID}} && $id == $links->{$id}{ID};
    }
    return 0;
} #_valid_link

sub _valid_links {
    my $self = shift;
    my $seen = shift;
    my $links = $self->get_links();

    for my $key (keys %$links) {
        next if $seen->{$key};
        $seen->{$key} = 1;
        return 0 unless $self->_valid_link( $links->{$key} );
        return 0 unless $links->{$key}->_valid_links( $seen );
    }
    return 1;
} #_valid_links

sub _check_owner {

} #_check_owner

sub _check_bombardment {

} #_check_bombardment

1;

__END__


=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 Eric Wolf

=cut
