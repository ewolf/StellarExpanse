package SG::App;

use strict;
use warnings;

use Data::ObjectStore;
use base 'Data::ObjectStore::Container';

our @mon = qw( jan feb mar apr may jun jly aug sep oct nov dec );
#
# Fields :
#   default_session
#   dummy_user
#   _sessions - sessid -> session obj
#   _emails - email to -> artist
#   _unames - user name -> artist
#


sub format_time {
    my( $self, $time ) = @_;
    unless( $time ) {
        return "?";
    }
    my( @thentime ) = localtime( $time );
    my( @nowtime )  = localtime( time );

    #
    #    0    1     2     3    4     5
    #  sec, min, hour, mday, mon, year
    #

    # different year
    if( $thentime[5] != $nowtime[5] ) {
        return sprintf( "%s %02d", $mon[$thentime[4]], $thentime[5] + 1900);
    }
    if( $thentime[4] != $nowtime[4] || $nowtime[3] > (1+$thentime[3])) {
        return sprintf( "%s %d", $mon[$thentime[4]], $thentime[3] );
    }
    if( $nowtime[3] == $thentime[3] ) {
        return sprintf( "today %02d:%02d", $thentime[2], $thentime[1] );
    }
    return sprintf( "yesterday %02d:%02d", $thentime[2], $thentime[1] );

}

sub _send_reset_request {
    my( $self, $user ) = @_;

    my $resets = $self->get__resets({});
    
    my $restok;
    my $found;
    until( $found ) {
        $restok  = int( rand( 10_000_000 ) );
        $found = ! $resets->{$restok};
    }
    $resets->{$restok} = $user;
    my $gooduntil = time + 3600;
    
    $user->set__reset_token( $restok );
    $user->set__reset_token_good_until( $gooduntil );

    my $site = $self->get_site;
    my $path = $self->get_sg_path;
    my $link = "https://$site$path\?path=/recover\&tok=$restok";
    
    my $body_html = <<"END";
<body>
<h1>Stellar Expanse Password Reset Request</h1>

<p>
To reset your password, please visit <a href="$link">$link</a>.
This link will work for an hour. If you did not request this, please let us know.
</p>

<p>Thanks</p>

<p style="font-style:italic">Scarf Poutine You Clone</p>

</body>
END

    my $body_txt = <<"END";
Stellar Expanse Password Reset Request

To reset your password, please visit 
$link.
This link will work for an hour. 
If you did not request this, please let us know.

Thanks
  Stellar Expanse

END

    my $msg = MIME::Lite->new(
        From => "noreply\@$site",
        To   => $user->get__email,
        Subject => 'Stellar Expanse Password Reset',
        Type => 'multipart/alternative',
        );
    
    $msg->attach(Type => 'text/plain', Data => $body_txt);
    $msg->attach(Type => 'text/html', 
                 Data => $body_html, 
                 Encoding => 'quoted-printable');
    
    $msg->send;

    
} #_send_reset_request


1;
