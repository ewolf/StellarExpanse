package StellarExpanse::Order;

use base 'Yote::Obj';

sub _resolve {
    my( $self, $message, $success ) = @_;
    $self->set_resolution_message( $message );
    $self->set_resolution( $success );
} #_resolve

1;

__END__
