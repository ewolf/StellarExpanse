package StellarExpanse::Order;

use base 'Yote::Obj';

sub _resolve {
    my( $self, $message, $success ) = @_;
    $self->set_resolution_message( $message );
    $self->set_resolution( $success );
    my $subj = $self->get_subject();
    $subj->remove_from_pending_orders( $self );
    $subj->add_to_completed_orders( $self );

    $subj->get_owner()->remove_from_all_pending_orders( $self );
    $subj->get_owner()->add_to_all_completed_orders( $self );
} #_resolve

1;

__END__
