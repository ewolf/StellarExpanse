package StellarExpanse::Game;

use strict;

use Config::General;
use StellarExpanse::Turn;

use base 'Yote::Obj';

#
# Starts the game on turn 0.
#
sub init {
    my $self = shift;

    $self->set_turn( 0 );
    my $first_turn = new StellarExpanse::Turn();
    $self->add_to_turns( $first_turn );

} #init

sub current_turn {
    my $self = shift;
    return $self->get_turns()->[$self->get_turn()];
}

#
# Returns the player object associated with the account, if any.
#
sub find_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    return $self->current_turn()->get_players()->{$acct->get_handle()};
} #find_player

#
# Adds the account to this game, creating a player object for it.
#
sub add_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $players = $self->current_turn()->get_players();
    if( $players->{$acct->get_handle()} ) {
        return { err => "account already added to this game" };
    }
    if( $self->needs_players() ) {
        my $player = new StellarExpanse::Player();
        $player->set_game( $self );
        $player->set_account_root( $acct_root );
        if( $data->{name} ) {
            $player->set_name( $data->{name} );
        }
        $players->{$acct->get_handle()} = $player;
        $acct_root->add_to_my_joined_games( $self );

        if( $self->needs_players() ) { #see if the game is now full
            return { msg => "added to game" };
        } else {
            $self->_start();
            return { msg => "added to game, which is now starting" };
        }
    }
    return { err => "game is full" };
} #add_player

#
# Removes the account from this game
#
sub remove_player {
    my( $self, $data, $acct_root, $acct ) = @_;
    my $players = $self->current_turn()->get_players();
    if( !$players->{$acct->get_handle()} ) {
        return { err => "account not a member of this game" };
    }
    if ($self->get_active()) {
        return { err => "cannot leave an active game" };
    }
    $acct_root->remove_from_my_joined_games( $self );
    delete $players->{$acct->get_handle()};
    return { msg => "player removed from game" };
}

#
# Returns number of players needed by game.
#
sub needs_players {
    my $self = shift;
    return (! $self->get_active() ) &&
        $self->get_number_players() > keys %{$self->get_turn()->get_players()};
} #needs_players

#
# Called automatically upon the last person joining
#
sub _start {
    my $self = shift;

    #
    # Load/use configs and merge into a master config
    #
    my $master_config = {};

    for my $conf qw( game empire base universe ) {
        my $get_cfg = "get_${conf}_config";
        my $conf_obj = new Config::General( -String => $self->get_flavor()->$get_cfg() );
        my( %conf ) = $conf_obj->getall;
        for my $key (keys %conf) {
            $master_config->{$key} = $conf{$key};
        }
    } #each config component

    my $players = $self->current_turn()->players();
    for my $player (@$players) {
        my $acct_root = $player->get_account_root();
        $acct_root->remove_from_pending_games( $self );
        $acct_root->add_to_active_games( $self );

        #
        # Set up starting stats
        #
        $player->set_resources( $self->get_starting_resources() );
        $player->set_tech_level( $self->get_starting_tech_level() );
        

        #
        # Give the player a system group for the empires.
        #
        my $group = $self->make_random_group( $master_config, 'empires', $player );

    } #each player

    
    $self->set_active( 1 );
    
} #_start

sub _make_random_group {
    my ( $self, $full_config, $basename, $owner) = @_;

    #
    # Looks up the configuration data structure for the basename.
    # Picks a random item in the configuration to use as a starting
    #  group where group is a nodal configuration of systems.
    #

    die "No $basename in configuration" if (!exists($full_config->{$basename}));
    my $part_config = $full_config->{$basename}->{group};

    my @keys = keys %$part_config;
    die "No groups in $basename configuration" if (scalar @keys == 0);
    my $choice = int(rand(scalar @keys));
    my $group_config = $part_config->{$keys[$choice]};


    # Now do more interesting stuff, sectors and internal link conversion
    my $sectors = $group_config->{sector};
    my @needProd;
    my @needMaxProd;

    my( %key2GSector );

    my $word = shift @{$self->{rand_names}};
    chomp $word;
    $word =~ s/[\'\"]//g;

    for my $key (sort keys %$sectors) {
        my $sector_template = $sectors->{$key};

        my $newsector = new GServ::SE::Sector();
        $newsector->set_game( $self );
        $self->add_to_sectors( $newsector );
        $key2GSector{$key} = $newsector;

        my $moniker = $key eq 'A' ? 'alpha' :
            $key eq 'B' ? 'beta' :
            $key eq 'C' ? 'gamma' :
            $key eq 'D' ? 'rho' : 
            $key eq 'E' ? 'epsilon' : 
            $key eq 'F' ? 'zeta' : 
            $key;
        $newsector->set_name( "$moniker $word" );

        
        my $prod_type = $sector_template->{prod_type} || 'default';

        # ---- set max and current production values ----
        my $rangeString = getProdValue($full_config, $sector_template, $prod_type, 'sectormaxprodrange');
        my ($min, $max) = split ' ',$rangeString;
        $min = $min || 0;   $max = $max || 0;
        
        my $maxprod = $max < $min ? $min : int(rand($max-$min+1) + $min);
        $newsector->set_maxprod( $max < $min ? $min : int(rand($max-$min+1) + $min) );

        my $rangeString = getProdValue($full_config, $sector_template, $prod_type, 'sectorprodrange');

        my ($min, $max) = split ' ',$rangeString;
        $min = $min || 0;   $max = $max || 0;
        my $curprod = $max < $min ? $min : int(rand($max-$min+1) + $min);

        if ($curprod > $maxprod) {
            $curprod = $maxprod;
        }	
        if( $owner && $sectors->{$key}{owner} != -1 ) {
            $newsector->set_owner( $owner );
            $owner->add_to_systems( $newsector );
            $maxprod = $sector_template->{maxprod};
            $curprod = $sector_template->{currprod};	    
        }
        $newsector->set_currprod( $curprod );
        $newsector->set_maxprod( $maxprod );
        $newsector->set_buildcap( 3 * $curprod );
        $key2GSector{$key}->set_outbound_links( $sectors->{$key}->{outbound_links} );	

    } #each sector group key

    #
    # Map out the sector to sector links that are internal to this group.
    #
    my $internal_links = $group_config->{internal_link};
    $internal_links = [ $internal_links ] unless ref( $internal_links );
    for my $link (@$internal_links) {
        $link =~ s/^\s*//; $link =~ s/\s*$//;
        my( $sectA, $sectB ) = map { $key2GSector{$_} } split ' ', $link, 2;
        die "Bad configuration, $link" unless $sectA && $sectB;
        $sectA->link_sectors( $sectB );
    } #each internal to group link

    my $group = new GServ::SE::Group();
    $group->set_sectors( [values %key2GSector] );
    return $group;
} #_make_random_group


1;

__END__
