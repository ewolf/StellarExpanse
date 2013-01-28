package StellarExpanse::Order;

use strict;

use base 'Yote::Obj';

sub _resolve {
    my( $self, $message, $success ) = @_;
    $self->set_resolution_message( $message );
    $self->set_resolution( $success );
    my $subj = $self->get_subject();
    $subj->remove_from_pending_orders( $self );
    $subj->get_owner()->remove_from_all_pending_orders( $self );
    push( @{$subj->get_owner()->get_all_completed_orders()->[$self->get_turn()+1]}, $self );
    push( @{$subj->get_completed_orders()->[$self->get_turn()+1]}, $self );
} #_resolve

1;

__END__
