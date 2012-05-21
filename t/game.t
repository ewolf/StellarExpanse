#!/usr/bin/perl

use strict;

use StellarExpanse::App;

use File::Temp qw/ :mktemp /;
use File::Spec::Functions qw( catdir updir );
use Test::More;
use Test::Pod;

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

BEGIN {
    for my $class (qw/App Game Group Player Ship Turn Flavor GlomGroup Order Sector TakesOrders/) {
        use_ok( "StellarExpanse::$class" ) || BAIL_OUT( "Unable to load StellarExpanse::$class" );
    }
}

my( $fh, $name ) = mkstemp( "/tmp/SQLiteTest.XXXX" );
Yote::ObjProvider::init(
    datastore      => 'Yote::SQLiteIO',
    sqlitefile     => $name,
    );
$Yote::ObjProvider::DATASTORE->ensure_datastore();
test_suite();

done_testing();

sub test_suite {

    #
    # Pick a flavor and set up a game.
    #
    my $app = new StellarExpanse::App();
    my $flavrs = $app->get_flavors();


    # create login account to use for app commands
    my $root = Yote::YoteRoot::fetch_root();
    ok( $root->create_login( { h => 'root', 
                               p => 'toor', 
                               e => 'foo@bar.com' } )->{l},
        "create account for root account" );
    Yote::ObjProvider::stow_all();
    my $login = Yote::ObjProvider::xpath("/_handles/root");
    my $acct = $app->_get_account( $login );
    
    ok( $root->create_login( { h => 'fred', 
                               p => 'toor', 
                               e => 'foofred@bar.com' } )->{l},
        "create account for root account" );
    Yote::ObjProvider::stow_all();

    my $fred_login = Yote::ObjProvider::xpath("/_handles/fred");
    my $fred_acct = $app->_get_account( $fred_login );

    ok( $root->create_login( { h => 'barny', 
                               p => 'toor', 
                               e => 'foobarny@bar.com' }  ), 
        "create account for root account" );
    Yote::ObjProvider::stow_all();

    my $barny_login = Yote::ObjProvider::xpath("/_handles/barny");
    my $barny_acct = $app->_get_account( $barny_login );

    
    is( scalar( @$flavrs ), 1, "default flavor" );

    my $flav = $flavrs->[0];
    
    my $res = $app->create_game( { name => "test game",
                                   number_players => 2,
                                   starting_tech_level => 1,
                                   starting_resources => 100,
                                   flavor => $flav,
                                 }, $acct );
    my $game = $res->{g};
    is( scalar( @{$game->get_turns()} ), 1, "Number of turns stored for initialized game" );

    is( $game->get_name(), "test game", "game name" );
    ok( $flav->_is( $game->get_flavor() ), "game has right flavor" );
    is( $game->get_turn_number(), 0, "first turn is 0" );
    my $turn = $game->_current_turn();
    is( $turn->get_turn_number(), 0, "turn number is 0" );
    is( $game->_find_player( $acct ), undef, "no players yet" );

    is( $game->active_player_count(), 0, "starts with no players" );
    ok( $game->get_active() == 0, "Not yet active" );

    my $res = $game->add_player( {}, $acct );
    is( $res->{msg}, "added to game", "added one player to game" );
    is( $game->active_player_count(), 1, "player count after add" );
    ok( $game->get_active() == 0, "Not yet active after adding one player" );

    my $res = $game->remove_player( {}, $acct );
    is( $res->{msg}, "player removed from game", "removed one player to game" );
    is( $game->active_player_count(), 0, "no players after remove" );

    my $res = $game->add_player( {}, $acct ); 
    is( $res->{msg}, "added to game", "added back one player to game" );
    is( $game->active_player_count(), 1, "one player after add back one" );

    my $res = $game->add_player( {}, $acct );
    like( $res->{err}, qr/already added/, "added a player already there" );
    is( $game->active_player_count(), 1, "one player after add back one" );

    my( $amy_acct ) = ( $acct );

    my $res = $game->add_player( {}, $fred_acct );
    is( $game->active_player_count(), 2, "number players" );

    ok( $game->get_active(), "Active after adding second player" );
    ok( ! $game->needs_players(), "Game no longer needs players" );
    
    my $res = $game->add_player( {}, $barny_acct );
    like( $res->{err}, qr/is full/, "added a player when game is full" );
    is( $game->active_player_count(), 2, "two players after failed to add one" );
    
    my( $amy, $fred ) = @{$game->_players()};
    $amy->set_acct( $amy_acct );
    $fred->set_acct( $fred_acct );

    is( $amy->get_resources(), 100, 'set up with correct starting resources');
    is( $amy->get_tech_level(), 1, 'set up with correct tech level');
    is( $fred->get_resources(), 100, 'set up with correct starting resources');
    is( $fred->get_tech_level(), 1, 'set up with correct tech level');

    ok( $turn->_check_ready() == 0, "Turn not ready" );

    my $res = $amy->mark_as_ready( { ready => 1, turn => 0 } );
    like( $res->{msg}, qr/Set Ready/i, "marking ready" );
    ok( $turn->_check_ready() == 0, "Turn not ready" );
    is( $turn->get_turn_number(), 0, "turn number is 0" );

    my $res = $amy->mark_as_ready( { ready => 0, turn => 0 } );
    like( $res->{msg}, qr/Set Ready/i, "marking ready" );
    ok( $turn->_check_ready() == 0, "Turn not ready" );
    is( $turn->get_turn_number(), 0, "turn number is 0" );

    my $res = $fred->mark_as_ready( { ready => 1, turn => 0 } );
    like( $res->{msg}, qr/Set Ready/i, "marking ready" );
    ok( $turn->_check_ready() == 0, "Turn not ready" );
    is( $turn->get_turn_number(), 0, "turn number is 0" );

    # ---------- take turn by marking ready

    my $res = $amy->mark_as_ready( { ready => 1, turn => 0 } );
    like( $res->{msg}, qr/Set Ready/i, "marking ready" );

    is( scalar( @{$game->get_turns()} ), 2, "Number of stored turns" );

    is( $turn->get_turn_number(), 1, "turn number is 1" );
    is( $game->get_turn_number(), 1, "game turn number is 1" );

    is( $amy->get_resources(), 120, 'correct resources after first turn');
    is( $amy->get_tech_level(), 1, 'correct tech level after first turn');
    is( $fred->get_resources(), 120, 'correct resources after first turn');
    is( $fred->get_tech_level(), 1, 'correct tech level after first turn');

    my $amy_sect = $amy->get_sectors();
    my( $amy_sector ) = @$amy_sect;
    is( scalar(@$amy_sect), 1, "Amy has one sector" );
    ok( $amy->_is( $amy_sect->[0]->get_owner() ), "Sector is owned by amy" );
    is( $amy_sect->[0]->get_currprod(), 20, "Prod at 20" );
    is( $amy_sect->[0]->get_maxprod(), 25, "Max Prod at 25" );

    my $sect = $fred->get_sectors();
    my( $fred_sector ) = @$sect;
    is( scalar(@$sect), 1, "Fred has one sector" );
    is( $sect->[0]->get_currprod(), 20, "Prod at 20" );
    is( $sect->[0]->get_maxprod(), 25, "Max Prod at 25" );
    is( $sect->[0]->get_buildcap(), 3 * 20, "Buildcap at three times current prod" );

    is( $turn->get_turn_number(), 1, "turn number is 1" );
    is( $game->get_turn_number(), 1, "game turn number is 1" );

    #
    # Check start chart for freds sector
    #
    my $fred_chart = $fred->get_starchart();
    ok( $fred_chart->_has_entry( $fred_sector ), "fred knows own sector" );
    ok( ! $fred_chart->_has_entry( $amy_sector ), "fred doesn't know amy's sector" );

    is( scalar( @{$amy->get_pending_orders()} ), 0, "No orders yet" );
    
    my $o1 = pass_order( $amy, { order => 'give_resources', amount => 1, recipient => $fred, turn => $turn->get_turn_number() }, 'give 1 to fred' );
    is( scalar( @{$amy->get_pending_orders()} ), 1, "first order" );

    my $o2 = pass_order( $amy, { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() }, 'give 3 to fred' );

    is( scalar( @{$amy->get_pending_orders()} ), 2, "second order" );

    fail_order( $amy, { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() + 3 }, qr/wrong turn/i, "Give resources for wrong turn" );

    fail_order( $amy, { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() - 1 }, qr/wrong turn/i, "Give resources for wrong turn" );
    is( scalar( @{$amy->get_pending_orders()} ), 2, "no valid 3rd" );
    my $res = $amy->mark_as_ready( { ready => 1, turn => $turn->get_turn_number() + 1 } );
    like( $res->{err}, qr/Not on turn/i, "error message for ready for wrong turn" );

    is( $turn->get_turn_number(), 1, "turn number still 1 after marking on wrong turn" );
    is( $game->get_turn_number(), 1, "game turn number is 1 after marking on wrong turn" );
    

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    is( $fred->get_resources(), 144, "resources fred turn 2 after being given some" );
    is( $turn->get_turn_number(), 2, "turn number is 2" );
    is( $game->get_turn_number(), 2, "game turn number is 2" );
    is( scalar( @{$game->get_turns()} ), 3, "Number of stored turns" );
    my $completed = $game->get_turns()->[2]->_players()->[0]->get_completed_orders()->[2];
    is( scalar( @$completed ), 2, "orders completed on this turn" );
    my $completed = $game->_current_turn()->_players()->[0]->get_completed_orders()->[2];
    is( scalar( @$completed ), 2, "orders completed on this turn" );
    is( $o1, $completed->[0], "first order ok" );
    is( $o2, $completed->[1], "2nd order ok" );
    ok( $o1->get_resolution(), "success giving 1" );
    ok( $o1->get_resolution(), "success giving 3" );
    like( $o1->get_resolution_message(), qr/^gave 1 /i, 'gave correct amount 1' );
    like( $o2->get_resolution_message(), qr/^gave 3 /i, 'gave correct amount 3' );
    is( scalar( @{$game->get_turns()->[2]->_players()->[0]->get_pending_orders()} ), 0, "orders pending for this turn" );
    is( scalar( @{$game->get_turns()->[1]->_players()->[0]->get_pending_orders()} ), 2, "last turn pending" );

    is( scalar( @{$amy->get_completed_orders()->[2]} ), 2, "order reset with turn" );
    is( scalar( @{$amy->get_pending_orders()} ), 0, "order reset with turn" );

    is( $amy->get_resources(), 136, 'correct  resources after turn and give');
    is( $amy->get_tech_level(), 1, 'set up with correct tech level');
    is( $fred->get_resources(), 144, 'correct resources after turn and give');
    is( $fred->get_tech_level(), 1, 'set up with correct tech level');

    my $prototypes = $flav->get_ships();
    my( $scout_p, $boat_p, $dest_p, $cruis_p, $battleship_p, $carrier_p, $fw_p, $owp_p, $ind_p, $tech_p ) = @$prototypes;

    # test build
    is( $scout_p->get_name(), 'Scout', "First ship is scout" );

    my $b1_o = build_order( $fred_sector, $scout_p, "build scout order" );
    my $b2_o = build_order( $fred_sector, $battleship_p, "build battleship order" );
    my $b3_o = build_order( $fred_sector, $boat_p, "build boat order" );
    # above costs 56. has 144 - ( 3 + 45 + 8 ) = 144 - 56 = 88

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );
    is( $fred->get_resources(), 108, "Freds resources" );
    is( $turn->get_turn_number(), 3, "turn number is 3" );
    is( $game->get_turn_number(), 3, "game turn number is 3" );
    my $completed = $game->_current_turn()->_players()->[1]->get_sectors()->[0]->get_completed_orders()->[3];
    my $pending = $game->_current_turn()->_players()->[1]->get_sectors()->[0]->get_pending_orders();
    is( scalar( @$completed ), 3, "build orders completed on this turn" );
    is( scalar( @$pending ), 0, "no pending orders after turn advance" );
    ok( $b1_o->get_resolution(), "build scout ok" );
    ok( $b2_o->get_resolution(), "build battleship ok" );
    ok( $b3_o->get_resolution(), "build boat ok" );

    my $player_ships = $fred->get_ships();
    my $sector_ships = $fred_sector->get_ships();
    is( @$player_ships, 3, "Player now as 3 ships" );
    is( @$sector_ships, 3, "Sector now as 3 ships" );
    my( $scout, $battleship, $boat ) = @$sector_ships;
    
    my $links = $fred_sector->_links();
    my $amy_links = $amy_sector->_links();
    is( @$links, 3, "three links from starting sector" );

    # this test can't use 'fail_order' because it sets up the wrong
    # root and acct
    like( $battleship->new_order( {
        from  => $fred_sector,
        to    => $links->[0],
        turn  => $turn->get_turn_number(),
        order => 'move',
                           },
                           $amy_acct )->{err}, 
          qr/player may not order this/i,
          "Cannot order someone else's ship" );


    #
    # try to move scout into an unexplored sector and move it back.
    #
    my $s_m1 = move_order( $scout, $fred_sector, $links->[0], "scout move from home order" );
    my $s_m2 = move_order( $scout, $links->[0], $fred_sector, "scout move back home order" );

    #
    # try to move boat like a scout. it has more movement but should stop at the unexplored place.
    #
    my $b_m2 = move_order( $boat, $fred_sector, $amy_links->[0], "boat order to unconnected sector" );
    my $b_m1 = move_order( $boat, $fred_sector, $links->[2], "boat order to explore" );
    my $b_m3 = move_order( $boat, $links->[2], $fred_sector, "boat order to move back home" );

    my $bo_1 = build_order( $amy_sector, $ind_p, "Industry for amy" );
    my $bo_2 = build_order( $amy_sector, $cruis_p, "Cruizer for amy" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    is( $fred->get_resources(), 128, "Fred resources" );
    ok( $b_m1->get_resolution(), "Boat 1st order ok" );
    ok( ! $b_m2->get_resolution(), "Boat 2nd order not ok" );
    like( $b_m1->get_resolution_message(), qr/^moved from/i, "boat order message 1" );
    like( $b_m2->get_resolution_message(), qr/does not link/i, "boat order message for does not link" );
    like( $b_m3->get_resolution_message(), qr/^out of movement/i, "boat order message for out of movement" );

    ok( $fred->_is( $links->[2]->get_owner() ), 'fred now owns sector' );
    ok( $boat->get_location()->_is( $links->[2] ), "boat moved to correct place" );
    ok( $scout->get_location()->_is( $fred_sector ), "scout moved then moved back home" );
    
    ok( $fred_chart->_has_entry( $fred_sector ), "fred knows own sector" );
    ok( ! $fred_chart->_has_entry( $amy_sector ), "fred doesn't know amy's sector" );
    ok( $fred_chart->_has_entry( $links->[2] ), "fred knows boat explored sector" );
    ok( $fred_chart->_has_entry( $links->[0] ), "fred knows scout explored sector" );
    ok( ! $fred_chart->_has_entry( $links->[1] ), "fred doesn't know unexplored sector" );

    ok( $bo_1->get_resolution(), "able to build an industry" );
    is( $amy_sector->get_currprod(), 21, "Industry updated" );
    ok( $bo_2->get_resolution(), "able to build ship" );
    my( $cruizer ) = @{$amy_sector->get_ships()};    
    $cruizer->set_name("FIRSTCRUIZ");

    # now link a fred system to amy's system so we can have a bit of combatishness.
    $amy_sector->_link_sectors( $links->[0] );
    $links->[2]->set_maxprod(3);
    my $ind_bo = build_order( $links->[2], $ind_p, "Industry for fred new system", 3 );
    
    #resources at 128 - 3*5 = 113

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $sm_1 = move_order( $scout, $fred_sector, $links->[0] );
    my $sm_2 = move_order( $scout, $links->[0], $amy_sector );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    # resources = 113 + 20 + 3
    ok( $ind_bo->get_resolution(), "able to build on external system" );
    is( $fred->get_resources(), 136, "Fred resources" );

    is( $links->[2]->get_currprod(), 3, "Industry updated for freds new planet" );
    ok( $sm_1->get_resolution(), "Scout to 0" );
    ok( $sm_2->get_resolution(), "Scout to amy sector" );
    ok( $fred_chart->_has_entry( $amy_sector ), 'fred knows of amy sector' );
    my $chart_entry = $fred_chart->_get_entry( $amy_sector );
    is( $chart_entry->get_seen_production(),  21, 'fred sees production' );
    is( $chart_entry->get_seen_owner(),  $amy, 'fred sees owner' );
    my $seen_ships = $chart_entry->get_seen_ships();

    is( scalar( @$seen_ships ), 1, 'fred sees 1 ship' );
    is( $seen_ships->[0], $cruizer, 'fred sees cruizer' );


    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $c_move = move_order( $cruizer, $amy_sector, $links->[0] );
    my $s_move = move_order( $scout, $amy_sector, $links->[0] );
    my $bt_move = move_order( $battleship, $fred_sector, $links->[0] );
    my $bo_move_1 = move_order( $boat, $links->[2], $fred_sector );
    my $bo_move_2 = move_order( $boat, $fred_sector, $links->[0] );
    my $fire_order = fire_order( $cruizer, $scout, 2," Cruizer firing on scout" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    for my $o ($c_move,$bt_move,$bo_move_1,$bo_move_2,$fire_order) {
        ok( $o->get_resolution() );
    }
    ok( ! $s_move->get_resolution(), "No scout to move" );

    # should have battleships, cruizer, boat in link 0, but not destroyed scout

    my $sector_ships = $links->[0]->get_ships();
    is( scalar( @$sector_ships ), 3, "3 ships now in link 0" );
    ok( $scout->{is_dead}, "Scout is dead" );
    ok( ! $scout->get_location(), "Scout not in any location" );

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

    # make a carrier and scout
    my $bo_car = build_order( $amy_sector, $carrier_p, "build a carrier" );
    my $bo_s2 = build_order( $amy_sector, $scout_p, "build a second scout" );
    my $bo_c2 = build_order( $amy_sector, $cruis_p, "build a cruizer" );
    my $bo_s3 = build_order( $amy_sector, $scout_p, "build a third scout" );

    move_order( $cruizer, $links->[0], $amy_sector, "Withdraw cruiser1" );

    
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );    

    is( scalar( @{$fred->get_sectors()} ), 3, "fred now has 3 sectors" );
    is( scalar( @{$links->[0]->get_ships()}), 2, '2 ships now in link 0' );
    ok( $fred->_is( $links->[0]->get_owner() ), "fred now owns link 0 " );
    is( scalar( @{$amy_sector->get_ships()}), 5, '5 ships now in amy sector' );
    my( $cruizer, $carrier, $scout2,$cruiser2, $scout3 ) = @{$amy_sector->get_ships()};
    $cruiser2->set_name("CRUIZER TWOZER");
    $scout3->set_name("OCTOPUSS");
    for my $o ($bo_car, $bo_s2,$bo_c2, $bo_s3 ) {
        ok( $o->get_resolution() );
    }
    

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $turn_n = $cruiser2->get_game()->_current_turn()->get_turn_number();
    my $cruiz_load_o = pass_order( $cruiser2, { order=>'load', carrier => $carrier, turn =>  $turn_n }, "Load cruiser onto carrier" );
    my $scout2_load_o = pass_order( $scout2, { order=>'load',carrier => $carrier, turn => $turn_n }, "Load scout onto carrier" );
    my $scout3_load_o = pass_order( $scout3, { order=>'unload',carrier => $carrier, turn => $turn_n }, "Unload scout from carrier its not yet on" );
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( ! $cruiz_load_o->get_resolution(), "Could not load cruizer" );
    ok( $scout2_load_o->get_resolution(), "Could load scout" );
    ok( ! $scout3_load_o->get_resolution(), "Could not unload not loaded scout" );

    # amy : cruizer, carrier, cruiser2, scout3
    is( scalar( @{$amy_sector->get_ships()}), 4, '4 ships now in amy sector since one loaded' );

    
    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $smo = move_order( $scout2, $amy_sector, $links->[0], "scout move order" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( ! $smo->get_resolution(), "Could not move loaded ship" );

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $o1 = move_order( $cruiser2, $amy_sector, $links->[0], "cruizer move order" );
    my $o2 = move_order( $carrier, $amy_sector, $links->[0], "carrier move order" );
    my $o3 = move_order( $scout3, $amy_sector, $links->[0], "scout 3 move order" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( $o1->get_resolution(), "cruizer2 can move" );
    ok( $o2->get_resolution(), "carrier can move" );
    ok( $o3->get_resolution(), "scout 3  can move" );

    # amy : cruiser2, carrier, scout 3
    # fred : battleship, boat
    is( scalar( @$sector_ships ), 5, "5 ships now in link 0" );

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
    my $uo = pass_order( $scout2, { turn  => $scout2->get_game()->_current_turn()->get_turn_number(), 
                           order => 'unload' } );
    my $lo = pass_order( $boat, { order => 'load', carrier => $carrier, turn  => $scout2->get_game()->_current_turn()->get_turn_number() } );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );


    is( scalar( @$sector_ships ), 6, "6 ships now in link 0 after unload" );
    ok( $uo->get_resolution(), "Scout unloaded" );
    ok( ! $lo->get_resolution(), "can't load boat" );

    # OOOOOOOOOOOOOOOOOOO
    my $bad_fire_1 = fire_order( $carrier, $scout2, 3, "bad fire 1" );
    my $good_fire_1 = fire_order( $carrier, $boat, 3, "good fire 1" );
    my $good_fire_2 = fire_order( $carrier, $battleship, 7, "good fire 2" );
    my $bad_fire_2 = fire_order( $carrier, $scout, 3, "good fire 2" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );
    
    ok( $good_fire_1->get_resolution(), "Could fire on boat" );
    ok( $good_fire_2->get_resolution(), "Could fire on battleship" );

    is( $battleship->get_hitpoints(), 45, "battleship healed all but one hitpoint" );
    is( $boat->get_hitpoints(), 4, "boat damanaged and cant heal" );

    ok( ! $bad_fire_1->get_resolution(), "Could not fire own ship" );
    ok( ! $bad_fire_2->get_resolution(), "Could not fire on scout. out of targets" );

    # OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

    # big battle. ships in links->[0] :
    # fred : battleship, boat
    # amy  : cruiser, 2xscout, carrier

    # make sure max industry of planet is 12 to test indict later
    $links->[0]->set_maxprod(12);
    my $ind_bo = build_order( $links->[0], $ind_p, "Industry for fred new system", 12 );

    my $f1 = fire_order( $carrier, $battleship, 10, "All on battleship" );
    my $f2 = fire_order( $carrier, $boat, 3, "fire on boat but out of juice" );
    
    my $ro = pass_order( $battleship, { turn  => $battleship->get_game()->_current_turn()->get_turn_number(),
                                        order => 'repair',
                                        repair_amount => 3 } );
    # battleships hp for next turn 45 - 10 + 3 (repair) + 6 = 44

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    is( $battleship->get_hitpoints(), 44, "battleships hp" );
    is( $boat->get_hitpoints(), 4, "boat hp" );
    ok( $f1->get_resolution(), "fired on battleship" );
    ok( ! $f2->get_resolution(), "Out of juice to fire on boat" );
    ok( $ro->get_resolution(), "Repair order for battleship" );
    is( $links->[0]->get_currprod(), 12, "current production of links->[0] boosted " );


    # OOOOOOOOOOOOOOO
    move_order( $battleship, $links->[0], $fred_sector, "Withdraw battleship" );
    move_order( $boat, $links->[0], $fred_sector, "Withdraw boat" );
    move_order( $cruiser2, $links->[0], $amy_sector, "Withdraw cruiser2" );
    #leaves a carrier which has beam strength 10

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    # check for bombardment and ownership
    ok( $fred->_is( $links->[0]->get_owner() ), "fred still owns links 0" );
    is( $links->[0]->get_currprod(), 2, "links 0 bombarded down to 2" );
    my $bt = build_order( $fred_sector, $tech_p, "building tech" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( $bt->get_resolution(), "tech build ok" );
    is( $links->[0]->get_currprod(), 0, "links 0 bombarded down to nothing" );
    is( $fred->get_tech_level(), 2, "Fred now at tech level 2" );

    # OOOOOOOOOOOOOOOOOOOOOO
    my( $missle_p ) = grep { $_->get_tech_level() == 2 && $_->get_self_destruct() } @$prototypes;
    my $bo = build_order( $fred_sector, $missle_p, "Building missile" );
    my $bo2 = build_order( $amy_sector, $missle_p, "Building missile" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    is( $links->[0]->get_currprod(), 0, "links 0 bombarded down to nothing" );
    ok( !$fred->_is( $links->[0]->get_owner() ), "fred no longer owns links 0" );
    ok( $amy->_is( $links->[0]->get_owner() ), "amy now owns links 0" );
    ok( $bo->get_resolution(), "Fred Built Missile" );
    ok( ! $bo2->get_resolution(), "Amy could not build missile due to tech level" );
    my( $missile ) = @{$bo->get_built()};

    # OOOOOOOOOOOOOOOOOOOOOO
    my $mo = move_order( $carrier, $links->[0], $fred_sector, "move carrier to fred sector to be missled" );

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( $mo->get_resolution(), "moved carrier to fred sector" );
    
    # OOOOOOOOOOOOOOOOOOOOOO
    my $fo = fire_order( $missile, $carrier, 15, "missle the carrier" );
    my $shipcount = scalar @{$fred_sector->get_ships()};

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    advance_turn( $turn );

    ok( $fo->get_resolution(), "missiled the carrier" );
    
    my( $still_missile ) = @{$bo->get_built()};
    ok( $still_missile->{is_dead}, "Missile exploaded. no longer in sector" );
    my $shipcount2 = scalar @{$fred_sector->get_ships()};
    is( $shipcount2, $shipcount - 1, "count of ships decreased by missile" );

    #carrier 15 - 12 + 2 = 5
    is( $carrier->get_hitpoints(), 5, "carrier damaged but healed some" );

    # check rewind
    $game()->rewind_to( $turn->get_turn_number() - 1 );
    


} #test_suite

sub move_order {
    my( $ship, $from, $to, $msg ) = @_;
    return pass_order( $ship,
                       {
                           from  => $from,
                           to    => $to,
                           turn  => $ship->get_game()->_current_turn()->get_turn_number(),
                           order => 'move'
                       },
                       $msg );
}

sub fire_order {
    my( $ship, $target, $amt, $msg ) = @_;
    return pass_order( $ship,
                       {
                           target  => $target,
                           beams   => $amt,
                           order => 'fire',
                           turn  => $ship->get_game()->_current_turn()->get_turn_number(),
                       },
                       $msg );
}

sub build_order {
    my( $sector, $ship, $msg, $qty ) = @_;
    return pass_order( $sector,
                       {
                           order => 'build',
                           turn  => $sector->get_game()->_current_turn()->get_turn_number(),
                           ship  => $ship,
                           quantity => $qty,
                       },
                       $msg );    
}


sub advance_turn {
    my $turn = shift;
    my $players = $turn->_players();
    for my $p (@$players) {
        $p->mark_as_ready( { ready => 1, turn => $turn->get_turn_number() } );
    }
    my $turns = $turn->get_game()->get_turns();

} #advance_turn

sub pass_order {
    my( $obj, $ord, $msg ) = @_;
    my $res = $obj->new_order( $ord, $obj->get_owner()->get_acct() );
    if( $res->{err} ) {
        ok( 0, ($msg || 'made order'). ' got error '.$res->{err} );
    }
    elsif( $res->{r} ) {
        ok( 1, $msg || 'made order' );
        return $res->{r};
    }
    ok( 0, $msg || 'made order' );
}

sub fail_order {
    my( $obj, $ord, $fail_regex, $msg ) = @_;
    like( $obj->new_order( $ord, $obj->get_owner()->get_acct() )->{err}, $fail_regex, $msg );
}
