#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Digest::MD5;

use lib '/home/coyo/proj/SpaceGame/lib';

use Data::ObjectStore;
use SG::App;
use SG::Player;
use SG::Dummy;
use SG::Image;
use SG::Session;

umask(0);
my $gid = getgrnam( 'www-data' );

our $site         = 'madyote.com';
our $basedir      = "/var/www";
our $sg_path      = '/cgi-bin/sg.cgi';
our $imagedir     = "$basedir/html/sg/images";

my $store = Data::ObjectStore::open_store( "/var/www/data/sg/", { group => $gid } );
my $root  = $store->load_root_container;

# set the root password
# set up question mark default avatar
# set up initial account?
# view logs?

#
# The SG app itself
#
my $app = $root->get_SG;
unless( $app ) {
    $app = $store->create_container( 'SG::App', {
            site      => $site,
            sg_path   => $sg_path,
            imagedir  => $imagedir,
                                     } );
    $root->set_SG( $app );
}

#
# set the default avatar
#
my $defava = $app->get__default_avatar;
unless( $defava ) {
    $defava = $store->create_container( 'SG::Image', {
        _original_name => 'question.png',
        extension => 'png',
        _origin_file => "/var/www/html/sg/images/question.png",
                                        } );
    $app->set__default_avatar( $defava );
}


#
# Dummy user with default session
#
my $user = $app->get_dummy_user;
unless( $user ) {
    my $un = 'dummy';

    $user = $store->create_container( 'SG::Dummy', {
        display_name => $un,
        _login_name  => $un,
        __avatar     => $app->get__default_avatar,
        _created     => time,
                                      } );
    $app->set_dummy_user( $user );
}

my $sess = $app->get_default_session;
unless( $sess ) {
    $sess = $store->create_container( 'SG::Session', {
        user => $user,
        ids => {
            $app => $app,
        },
                                      } );
    $app->set_default_session( $sess );
    my $sessions = $app->get__sessions({}); 
    $sessions->{0} = $sess;    
    $user->set__session( $sess );
}


$store->save;

print "Stellar Expanse ADMIN. Type 'help' to get help\n\nSG>";
while( <STDIN> ) {
    if( /^(\?|help)/ ) {
        print "SG ADMIN COMMANDS\n";
        print join( "\n",
                    "? or help - this entry",
                    "defava - show default avatar image",
                    "defava <filename> - set default avatar image",
                    "exit - end admin program",
                    "passwd <user> - set user password",
                    "users - list users",
                    
                    "admin <user> - make user into an admin",
                    "logs - list logs (unimplemented)",

                    "user <user> - details about user",

                    "" );
    }
    elsif( /^\s*admin\s+(\S+)/ ) {
        my $un = $1;
        my $unames = $app->get__users({});
        my $user = $unames->{lc($un)};
        if( $user ) {
            $user->set__is_admin(1);
            print "'$un' is now an admin.\n";
        } else {
            print "User '$un' not found\n";
        }
    }
    elsif( /^\s*unadmin\s+(\S+)/ ) {
        my $un = $1;
        my $unames = $app->get__users({});
        my $user = $unames->{lc($un)};
        if( $user ) {
            $user->set__is_admin(0);
            print "'$un' is no longer an admin.\n";
        } else {
            print "User '$un' not found\n";
        }
    }
    elsif( /^\s*defava\s+(\S+)/ ) {
        $defava->set__origin_file( $1 );
        print "Default Avatar Image set to "  . $defava->get__origin_file . "\n";
    }
    elsif( /^\s*defava/ ) {
        print "Default Avatar Image at "  . $defava->get__origin_file . "\n";
    }
    elsif( /^\s*exit/ ) {
        exit;
    }
    elsif( /^\s*users/ ) {
        my $unames = $app->get__users({});
        my( @uns ) = sort keys %$unames;
        my $longest;
        if( @uns ) {
            ( $longest ) = sort { $b <=> $a } map { length($_) } (@uns);
            my $hl = ($longest-4)/2;
            printf "%${hl}s%s Email\n","User", " "x$hl
        } else {
            print "No users found\n";
        }
        for my $un (@uns) {
            my $user = $unames->{$un};
            printf "%${longest}s %s %s\n",$un, $user->get__email, $user->get__is_admin ? 'admin-user' : '';
            my $at = $user->get__active_time;
            unless( $at ) {
                my $comic = $user->get__playing;
                if( $comic ) {
                    $comic->set__player( undef );
                    $user->set__playing( undef );
                }
            }
            my $del = time - $at;
            if( $del > 3600 ) {
                printf " AT ($del): %d\n", int($del/3600);
                my $comic = $user->get__playing;
                if( $comic ) {
                    print "Clear ?";
                    my $ans = <STDIN>;
                    if( $ans =~ /^yes/i ) {
                        $comic->set__player( undef );
                        $user->set__playing( undef );
                    }
                }
            }
        }
    }
    elsif( /^\s*passwd\s+(\S+)/ ) {
        my $un = $1;
        my $unames = $app->get__users({});
        my $user = $unames->{lc($un)};
        if( $user ) {
            print "New Password for user $un :";
            my $pw1 = <STDIN>;
            chomp( $pw1 );
            print "Repeat Password :";
            my $pw2 = <STDIN>;
            chomp( $pw2 );
            if( $pw1 ne $pw2 ) {
                print "Passwords don't match\n";
            } elsif( length($pw1) < 4 ) {
                print "Password too short\n";
            } else {
                $user->_setpw( $pw1 );
                print "Password updated\n";
            }
        } else {
            print "User '$un' not found\n";
        }
    } # password <user>
    
    $store->save;
    print "SG>";
}


__END__
