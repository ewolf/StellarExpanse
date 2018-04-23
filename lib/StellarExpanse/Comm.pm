package StellarExpanse::Comm;

use strict;

use base 'Yote::UserObj';

sub _init {
    my $self = shift;
    $self->set__convos_with( {} );
} #_init

sub open_channel {
    my( $self, $with_handle, $acct ) = @_;
    my $app = Yote::WebRoot::fetch_webroot()->fetch_app_by_class( 'StellarExpanse::App' );
    my $other_acct = $app->_hash_fetch( '_account_handles', $with_handle );
    die "Converse needs an account" unless $acct && $other_acct;
    my $convo = $self->_hash_fetch( '_convos_with', $other_acct->get_handle() );
    unless( $convo ) {
	 $convo = new Yote::Obj( { with => $other_acct, with_name => $other_acct->get_handle() } );
	 $self->_hash_insert( '_convos_with', $other_acct->get_handle(), $convo );
	 $other_acct->get_comm()->_hash_insert( '_convos_with', $acct->get_handle(), $convo );
    }
    return $convo;
} #open_channel

1;

__END__
