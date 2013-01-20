package StellarExpanse::Game;

use strict;

use Config::General;
use StellarExpanse::Group;
use StellarExpanse::GlomGroup;
use StellarExpanse::Sector;
use StellarExpanse::StarChart;
use StellarExpanse::Turn;
use StellarExpanse::Player;
use Yote::Util::MessageBoard;

use base 'Yote::Obj';

#
# Starts the game on turn 0.
#
sub _init {
    my $self = shift;
    $self->SUPER::_init();
    $self->set_turn_number( 0 );
    my $first_turn = new StellarExpanse::Turn();
    $first_turn->set_turn_number( 0 );
    $first_turn->set_game( $self );
    $self->add_to_turns( $first_turn );
    $self->set_messageboard( new Yote::Util::MessageBoard() );
} #init

sub _on_load {
    my $self = shift;
    $self->{NO_DEEP_CLONE} = 1;
}

sub _current_turn {
    my $self = shift;
    return $self->get_turns()->[$self->get_turn_number()];
}

sub rewind_to {
    my( $self, $data, $acct ) = @_;
    #rewinds this game to a point (data->{t})
    my $old_turn = $data->{t};
    if( $old_turn >= $self->get_turn_number() || $old_turn < 1 ) {
        die "Cannot move to future turns";
    }
    $self->set_turn_number( $old_turn );
    return "rewound to turn $old_turn";
} #rewind_to

#
# Returns the player object associated with the account, if any.
#
sub _find_player {
    my( $self, $acct ) = @_;
    return undef unless $acct;
    return $self->_current_turn()->get_players()->{$acct->get_login()->get_handle()};
} #_find_player

#
# Adds the account to this game, creating a player object for it.
#
sub add_player {
    my( $self, $data, $acct ) = @_;
    my $login = $acct->get_login();
    my $players = $self->_current_turn()->get_players();
    if( $players->{$login->get_handle()} ) {
        die "account '" . $login->get_handle() . "' already added to this game";
    }
    if( $self->needs_players() ) {
        my $player = new StellarExpanse::Player();
        $player->set_turn( $self->_current_turn() );
        $player->set_game( $self );
        $player->set_account( $acct );
        $player->set_name( $login->get_handle() );
        $players->{$login->get_handle()} = $player;
        if( $self->needs_players() ) { #see if the game is now full
	    
	    # debug with a path to root

	    print STDERR Data::Dumper->Dump([$self,Yote::ObjProvider::info( $acct ),Yote::ObjProvider::info($acct->get_pending_games()),"_______________________B4_______________"]);
	    $acct->add_once_to_pending_games( $self );
	    print STDERR Data::Dumper->Dump([$self,Yote::ObjProvider::info($acct->get_pending_games()),"_______________________AR_______________"]);
	    print STDERR Data::Dumper->Dump([ $Yote::ObjProvider::DIRTY, $Yote::ObjProvider::CHANGED, $Yote::ObjManager::LOGIN_OBJS]);
            return "added to game";
        } else {
            $self->_start();
 	    my $all_players = $self->_players();
	    for my $p (@$all_players) {
		$p->get_account()->add_once_to_active_games( $self );
		$p->get_account()->remove_all_from_pending_games( $self );
	    }
            return "added to game, which is now starting";
        }
    }
    die "game is full";
} #add_player

#
# Removes the account from this game
#
sub remove_player {
    my( $self, $data, $acct ) = @_;
    my $login = $acct->get_login();
    my $players = $self->_current_turn()->get_players();
    if( !$players->{$login->get_handle()} ) {
        die "account not a member of this game";
    }
    if ($self->get_active()) {
        die "cannot leave an active game";
    }
    print STDERR Data::Dumper->Dump(["BEFORE--------------",$acct->get_pending_games(),Yote::ObjProvider::get_id($acct->get_pending_games()),$Yote::ObjProvider::DIRTY,$Yote::ObjManager::LOGIN_OBJS,$acct]);
    $acct->remove_all_from_pending_games( $self );
    print STDERR Data::Dumper->Dump(["AFTER--------------",$acct->get_pending_games(),Yote::ObjProvider::get_id($acct->get_pending_games()),$Yote::ObjProvider::DIRTY,$Yote::ObjManager::LOGIN_OBJS]);
    my $handle = $login->get_handle();
    delete $players->{$handle};
    return "player '$handle' removed from game";
} #remove_player

sub active_player_count {
    my $self = shift;
    return scalar( keys %{$self->_current_turn()->get_players()} );
} #active_players

#
# Returns number of players needed by game.
#
sub needs_players {
    my $self = shift;
    return ( 0 == $self->get_active() ) &&
        $self->get_number_players() > keys %{$self->_current_turn()->get_players()};
} #needs_players

#
# How many have joined for pending games.
#
sub joined_playercount {
    my $self = shift;
    return scalar( keys %{$self->_current_turn()->get_players()} );
}

sub _players {
    my $self = shift;
    return [values %{$self->_current_turn()->get_players()}];
}

#
# Called automatically upon the last person joining
#
sub _start {
    my $self = shift;

    my $flav = $self->get_flavor();
    my $turn = $self->_current_turn();

    #
    # Load/use configs and merge into a master config
    #
    my $master_config = {};

    for my $conf (qw/ game empire base universe/ ) {
        my $get_cfg = "get_${conf}_config";
        my $conf_obj = new Config::General( -String => $flav->$get_cfg() );
        my( %conf ) = $conf_obj->getall;
        for my $key (keys %conf) {
            $master_config->{$key} = $conf{$key};
        }
    } #each config component

    #
    # Temporary variables used for building the sectors.
    # 
    my @links;
    my $unclaimed_groups = [];
    my $empire_groups = [];
    my $sector_count = 0;


    my $words = $flav->get_sector_names();
    my @words = @$words;
    unless( @words ) {
        # use random dictionary words
        open( IN, "</etc/dictionaries-common/words" );

my $dcount = 0;        # < for testing only > #
        while( <IN> ) {
            chomp;
            next unless /^[a-z]+$/ && length( $_ ) > 2;
            push @words, $_;
last if ++$dcount > 200;        # < for testing only > #
        }
        close( IN );
    }

    #
    # Configure each player and their starting group.
    #
    my $players = $turn->_players();
    for my $player (@$players) {
        my $acct = $player->get_account();
        $acct->remove_all_from_pending_games( $self );
        $acct->add_once_to_active_games( $self );

        #
        # Set up starting stats
        #
        $player->set_resources( $self->get_starting_resources() );
        $player->set_tech_level( $self->get_starting_tech_level() );
        

        #
        # Give the player a sector group for the empires.
        #
        my $group = $self->_make_random_group( $master_config, 'empires', $player, \@words );
        my $gsecs = $group->{sectors};
        my $chart = new StellarExpanse::StarChart();
        $chart->set_owner( $player );
        $chart->set_game( $self );

        $player->set_starchart( $chart );
        my( $capitol ) = grep { $_->get_owner() } @$gsecs;
        $chart->_update( $capitol );

        $group->{is_empire} = 1;
        $sector_count += $group->sector_count();
        push @$empire_groups, $group;
    } #each player

    #
    # Create a basegroups sector (if a master_config exists) or a vanilla groups sector.
    #
    my $base_group_name = $master_config->{basegroups} ? 'basegroups' : 'groups';
    my $g = $self->_make_random_group( $master_config, $base_group_name, undef, \@words );
    $sector_count += $g->sector_count();
    push @$unclaimed_groups, $g;

    #
    # Continue to make sectors until the target number of sectors is reached.
    # 
    while( $sector_count < $master_config->{target_sector_count} ) {
        my $g = $self->_make_random_group($master_config, "groups", undef, \@words );
        $sector_count += $g->sector_count();
        push @$unclaimed_groups, $g;
    }

    #
    # Pick a starting group, then glom other groups into it until all the groups are connected.
    #
    my( @selector );
    for my $g (@$unclaimed_groups) {
        for(1..$g->get_outbound_count()) {
            push @selector, $g;
        }
    }

    #
    # Create an empty 'glom group', then pick a random group of sectors to start and join the 
    # glom group. Then add all the rest of the unclaimed (non-empire) groups to the glom.
    # 
    my $start_group = $selector[int(rand(scalar @selector))];

    my $glom = new StellarExpanse::GlomGroup();
    $glom->glom( $start_group );

    for my $g (@$unclaimed_groups) {
        next if $g eq $start_group;
        $glom->glom( $g );	
    }

    #
    # Connect all the empire groups that have loose ends to the glom group. 
    # There are cases where this can fail, so retry a number of times. 
    # By the end, all empire groups
    # will be 'glommed' together with the other sectors, their outgoing links all connected.
    #
    my( @free_groups ) = grep { $_->get_outbound_count() > 0 } (@$empire_groups);
    my $tries = 0;
    my $unconnected_empire_sectors = 0;
    for my $fg (@free_groups) {
        $unconnected_empire_sectors += $fg->get_outbound_count();
    }
    while( @free_groups && $unconnected_empire_sectors > 1 && $tries < 10 ) {
        for my $g (@free_groups) {
            $glom->connect( $g ) if $g->get_outbound_count() > 0;
        }
        ( @free_groups ) = grep { $_->get_outbound_count() > 0 } (@free_groups);
        ++$tries;
        $unconnected_empire_sectors = 0;
        for my $fg (@free_groups) {
            $unconnected_empire_sectors += $fg->get_outbound_count();
        }
    }
    die "Unable to make connections" if $tries == 10;

    #
    # Connect any loose ends together inside the glom group.
    #
    my( @free_groups ) = grep { $_->get_outbound_count() > 0 } (@$unclaimed_groups);
    while( $glom->get_unlinked_groups() > 1 && @free_groups > 1) {
        for my $g (@free_groups) {
            $glom->connect( $g ) if $g->get_outbound_count() > 0;
        }
        ( @free_groups ) = grep { $_->get_outbound_count() > 0 } (@free_groups);
    }

#
# Deprecating the making of the map for now
#
# -------- make map ------------------------------------
#     my $gv = new GraphViz(directed => 0);    
#     my %seen;
#     for my $g (@$empire_groups,@$unclaimed_groups) {
#         my $sects = $g->{sectors};
#         for my $s (@$sects) {
#             $gv->add_node( $s->{ID}, 
#                            label => $s->get_name( $s->{ID} ),
#                 );
#             my $links = $s->get_links();
#             for my $link_to (keys %$links) {
#                 unless( $seen{$link_to}{$s->{ID}} ) {
#                     $gv->add_edge( $s->{ID} => $link_to );
#                     $seen{$s->{ID}}{$link_to} = 1;
#                 }
#             } #each link
#         } #each sector
#     } #each group
#
#     my $dir = "/home1/irrespon/proj/data/StellarExpanse/maps/$self->{ID}";
#     mkdir $dir unless -e $dir;
#     open(FH, ">$dir/map.png");
#     print FH $gv->as_png;
#     close(FH);
#---
#
#    $self->_make_player_maps( { map { $_->{ID} => $_  } @$players } );
#
    
    $self->set_active( 1 );
    
} #_start

sub _end {
    my $self = shift;
    $self->set_active( 2 );
} #_end

#
# Use the game full config to create a group of sectors that belong together. Return the group.
#
sub _make_random_group {
    my ( $self, $full_config, $basename, $owner, $words ) = @_;

    my $flav = $self->get_flavor();
    my $turn = $self->_current_turn();

    #
    # Looks up the master_config data structure for the basename.
    # Picks a random item in the master_config to use as a starting
    #  group where group is a nodal master_config of sectors.
    #
    die "No $basename in master_config" if (!exists($full_config->{$basename}));
    my $part_config = $full_config->{$basename}->{group};

    my @keys = keys %$part_config;
    die "No groups in $basename master_config" if (scalar @keys == 0);
    my $choice = int(rand(scalar @keys));
    my $group_config = $part_config->{$keys[$choice]};


    # Now do more interesting stuff, sectors and internal link conversion
    my $sectors = $group_config->{sector};
    my @needProd;
    my @needMaxProd;

    my( %key2GSector );

    my $word = splice @$words, int(rand(@$words)), 1;

    for my $key (sort keys %$sectors) {
        my $sector_template = $sectors->{$key};

        my $newsector = new StellarExpanse::Sector();
        $newsector->set_game( $self );
        $turn->add_to_sectors( $newsector );
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
        my $rangeString = _getProdValue($full_config, $sector_template, $prod_type, 'SectorMaxProdRange');
        my ($min, $max) = split ' ',$rangeString;
        $min = $min || 0;   $max = $max || 0;
        
        my $maxprod = $max < $min ? $min : int(rand($max-$min+1) + $min);
        $newsector->set_maxprod( $maxprod );

        if( $owner && $sectors->{$key}{owner} != -1 ) {
            $newsector->set_owner( $owner );
            $owner->add_to_sectors( $newsector );
            $maxprod = $sector_template->{maxprod};
            my $curprod = $sector_template->{currprod};
            if ($curprod > $maxprod) {
                $curprod = $maxprod;
            }
            $newsector->set_maxprod( $maxprod );
            $newsector->set_currprod( $curprod );
            $newsector->set_buildcap( 3 * $curprod );
        }

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
        die "Bad master_config, $link" unless $sectA && $sectB;
        $sectA->_link_sectors( $sectB );
    } #each internal to group link

    my $group = new StellarExpanse::Group();
    $group->set_sectors( [values %key2GSector] );
    return $group;
} #_make_random_group


#
# Gets the production value for a production type
#
sub _getProdValue {
    my( $full_config, $sector_template, $prod_type, $prod_key ) = @_;
    # create a list of value options, like [0,1,1,1,5,5,5,8,9] and randomly pick from that list. The 
    # list is weighted, and the weightings show up as repetition of a value in the list.
    my $rangeStringOpts = $sector_template->{$prod_key} || 
        _buildRangeStringOptList($sector_template->{prod_type_group}{$prod_type}, $prod_key) ||
        _buildRangeStringOptList($full_config->{prod_type_group}{$prod_type}, $prod_key)     ||
        ["0"];

    my $opt = 0;
    if( scalar( @$rangeStringOpts ) ) {
        $opt = $rangeStringOpts->[int(rand(scalar @{$rangeStringOpts}))];
    }
    return $opt;
} #_getProdValue


#
# Builds a list of values that the group has for the given key.
# The values have a weight, and the values appear as many times
# in the list as the value of their weight.
#
sub _buildRangeStringOptList {
    my ($group, $key) = @_;
    my $rangeStringOpts;
    my $subgroup = $group->{prod_type};
    
    foreach my $ptg (values %{$subgroup}) {
        my $s = $ptg->{$key} || 0;
        my $c = $ptg->{weight} || 1;
        for (my $i = 0; $i < $c; ++$i) {
            push @$rangeStringOpts, $s;
        }
    }   
    return $rangeStringOpts;
} #_buildRangeStringOptList


#
# Called for each turn. Deprecated out for now.
#
# sub _make_player_maps {
#     my $self = shift;

#     my $players = shift || $self->get_players();
#     for my $player (values %$players) {
#         # map 
#         my $g = new GraphViz( directed => 0, ratio => 8.0/7 );
#         my $map = $player->get_maps({});
#         my( %mapped_edges );
#         for my $mnode (values %$map) {
#             my $loc = $mnode->get_sector();
#             my $owner = $loc->get_owner();

#             my $label = $loc->get_name();
#             $g->add_node( $loc->{ID},
#                           label  => $label,
#                           style  => $loc->get_owner() eq $player ? 'solid' : 'filled', 
#                           shape  => 'box',
#                           width  => 0.3,
#                           height => 0.3,
#                           fontsize => 10,
#                           URL => $loc->{ID},
#                           color => $loc->get_owner() eq $player ? 'Turquoise' :
#                           $loc->get_owner() ? 'pink' : 'Coral',
#                 );
#             my $connections = $loc->get_links();
#             for my $con (values %$connections) {
#                 # check if this node leads to an other mapped node, or to an unknown connection.
#                 if( $map->{$con->{ID}} ) {
#                     #known
#                     $g->add_edge( $con->{ID}, $loc->{ID} ) 
#                         unless $mapped_edges{"$con->{ID} $loc->{ID}"} || $mapped_edges{"$loc->{ID} $con->{ID}"};
#                     $mapped_edges{"$con->{ID} $loc->{ID}"} = 1;
#                 } else {
#                     #add unexplored node
#                     $g->add_node( $con->{ID},
#                                   label  => $con->get_name( ),
#                                   style  => 'filled', 
#                                   shape  => 'box',
#                                   width  => 0.3,
#                                   height => 0.3,
#                                   fontsize => 10,
#                                   URL => $con->{ID},
#                                   color => 'Chartreuse',
#                         );
#                     $g->add_edge( $con->{ID}, $loc->{ID} ) 
#                 }
#             } #each connection from node
#         } #each node in players map
#         my $turn = $self->get_turn();

#         my $base = Cwd::getcwd();
#         my $dir = "/home1/irrespon/proj/data/StellarExpanse/maps/$self->{ID}/$turn";

#         mkdir $dir unless -e $dir;
#         open(FH, ">$dir/".$player->{ID}.".png");
#         print FH $g->as_png;
#         close(FH);
#         open(FH, ">$dir/".$player->{ID}.".cmapx");
#         my $cpam = $g->as_cmapx;
#         print FH $cpam;
#         close(FH);    

#         # 3.png: PNG image, 795 x 504, 8-bit/color RGBA, non-interlaced
#         my $x = `file $dir/$player->{ID}.png`;
#         my( $w, $h );
#         if( $x =~ /^[^,]*,\s*(\d+)\s*[Xx]\s*(\d+)/ ) {
#             ( $w, $h ) = ( $1, $2 );
#         }

#         my $jsfile = "$dir/$player->{ID}.js";
#         open(FH, ">$jsfile");
#         print FH "function set_dimentions() {\n";
#         print FH "img_w = $w;\nimg_h = $h;\n}\n";
# #<area shape="rect" href="#se79" title="pasionfruit(79)\nprod 5/5" alt="" coords="557,379,672,424"/>
#         print FH "function init_map(c) {\n";
#         while( $cpam =~ /(.*?)href=\"([^\"]*)\"(.*?)coords=\"([^\"]*)\"(.*)/is ) {
#             my( $name, $coords ) = ( $2, $4 );
#             $cpam = $5;
#             my( $x1, $y1, $x2, $y2 ) = split( /,/, $coords );
#             my $w = $x2 - $x1;
#             my $h = $y2 - $y1;
#             print FH "c.add_control( make_click( c, function() { show_sector($name) }, $x1, $y1, $w, $h ) );\n";
#         }
#         print FH "}\n";
#         close( FH );

#     } #each player
# } #_make_player_maps


1;

__END__
