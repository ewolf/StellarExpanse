package StellarExpanse::Order;

use base 'Yote::Obj';

sub _resolve {
    my( $self, $message, $success ) = @_;
    $self->set_resolution_message( $message );
    $self->set_resolution( $success );
    my $subj = $self->get_subject();
    $subj->remove_from_pending_orders( $self );
    push( @{$subj->get_completed_orders()->[$self->get_turn()+1]}, $self );
} #_resolve

1;

__END__
