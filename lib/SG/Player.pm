package SG::Player;

use strict;
use warnings;

use Data::ObjectStore;
use base 'Data::ObjectStore::Container';

use Digest::MD5;
use File::Copy;
use MIME::Lite;

sub _setpw {
    my( $self, $pw ) = @_;
    my $un = $self->get__login_name;
    my $enc_pw = crypt( $pw, length( $pw ) . Digest::MD5::md5_hex($un) );
    $self->set__enc_pw( $enc_pw );
} #_setpw

sub _checkpw {
    my( $self, $pw ) = @_;
    my $un = $self->get__login_name;
    my $enc_pw = crypt( $pw, length( $pw ) . Digest::MD5::md5_hex($un) );
    $enc_pw eq $self->get__enc_pw;
} #_checkpw

sub _display {
    my $self = shift;
    my $ln = $self->get__login_name;
    my $dn = $self->get_display_name;
    if( $ln ne $dn ) {
        return "$dn/$ln";
    } else {
        return $ln;
    }
} #_display

sub _send_confirmation_email {
    my( $self ) = @_;
}


1;
