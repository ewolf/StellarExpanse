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
$Yote::ObjProvider::DATASTORE->init_datastore();
test_suite();

done_testing();

sub test_suite {

    # create login account to use for app commands
    my $root = Yote::AppRoot::fetch_root();
    like( $root->_process_command( { c => 'create_account', d => {h => 'vroot', p => 'vtoor', e => 'vfoo@bar.com' }  } )->{r}, qr/created/i, "create account for root account" );
    my $acct = Yote::ObjProvider::xpath("/handles/root");
    my $acct_root = $root->_get_account_root( $acct );

    like( $root->_process_command( { c => 'create_account', d => {h => 'vfred', p => 'vtoor', e => 'vfoofred@bar.com' }  } )->{r}, qr/created/i, "create account for root account" );
    my $fred_acct = Yote::ObjProvider::xpath("/handles/fred");
    my $fred_acct_root = $root->_get_account_root( $acct );

    like( $root->_process_command( { c => 'create_account', d => {h => 'vbarny', p => 'vtoor', e => 'vfoobarny@bar.com' }  } )->{r}, qr/created/i, "create account for root account" );
    my $barny_acct = Yote::ObjProvider::xpath("/handles/barny");
    my $barny_acct_root = $root->_get_account_root( $acct );

    #
    # Pick a flavor and set up a game.
    #
    my $app = new StellarExpanse::App();
    my $flavrs = $app->get_flavors();
    
    is( scalar( @$flavrs ), 1, "default flavor" );

    my $flav = $flavrs->[0];
 
    my $res = $app->create_game( { name => "test game",
                                   number_players => 2,
                                   starting_tech_level => 1,
                                   starting_resources => 100,
                                   flavor => $flav,
                                 }, $acct_root, $acct );
    my $game = $res->{g};
    is( scalar( @{$game->get_turns()} ), 1, "Number of turns stored for initialized game" );

    is( $game->get_name(), "test game", "game name" );
    ok( $flav->is( $game->get_flavor() ), "game has right flavor" );
    is( $game->get_turn_number(), 0, "first turn is 0" );
    my $turn = $game->current_turn();
    is( $turn->get_turn_number(), 0, "turn number is 0" );
    is( $game->_find_player( $acct ), undef, "no players yet" );

    is( $game->active_player_count(), 0, "starts with no players" );
    ok( $game->get_active() == 0, "Not yet active" );

    my $res = $game->add_player( {}, $acct_root, $acct );
    is( $res->{msg}, "added to game", "added one player to game" );
    is( $game->active_player_count(), 1, "player count after add" );
    ok( $game->get_active() == 0, "Not yet active after adding one player" );

    my $res = $game->remove_player( {}, $acct_root, $acct );
    is( $res->{msg}, "player removed from game", "removed one player to game" );
    is( $game->active_player_count(), 0, "no players after remove" );

    my $res = $game->add_player( {}, $acct_root, $acct );
    is( $res->{msg}, "added to game", "added back one player to game" );
    is( $game->active_player_count(), 1, "one player after add back one" );

    my $res = $game->add_player( {}, $acct_root, $acct );
    like( $res->{err}, qr/already added/, "added a player already there" );
    is( $game->active_player_count(), 1, "one player after add back one" );

    my( $amy_acct_root, $amy_acct ) = ( $acct_root, $acct );

    my $res = $game->add_player( {}, $fred_acct_root, $fred_acct );
    is( $game->active_player_count(), 2, "number players" );

    ok( $game->get_active(), "Active after adding second player" );
    ok( ! $game->needs_players(), "Game no longer needs players" );
    
    my $res = $game->add_player( {}, $barny_acct_root, $barny_acct );
    like( $res->{err}, qr/is full/, "added a player when game is full" );
    is( $game->active_player_count(), 2, "two players after failed to add one" );
    
    my( $amy, $fred ) = @{$game->_players()};
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

#    {

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

        my $sect = $amy->get_sectors();
        my( $amy_sector ) = @$sect;
        is( scalar(@$sect), 1, "Amy has one sector" );
        ok( $amy->is( $sect->[0]->get_owner() ), "Sector is owned by amy" );
        is( $sect->[0]->get_currprod(), 20, "Prod at 20" );
        is( $sect->[0]->get_maxprod(), 25, "Max Prod at 25" );

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
#    }

    #
    # test give order give_resources
    #
#    {
        is( scalar( @{$amy->get_pending_orders()} ), 0, "No orders yet" );
        like( $amy->new_order( { order => 'give_resources', amount => 1, recipient => $fred, turn => $turn->get_turn_number() }, $amy_acct_root, $amy_acct )->{msg}, qr/gave order/i, "Give resources" );
        is( scalar( @{$amy->get_pending_orders()} ), 1, "first order" );
        like( $amy->new_order( { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() }, $amy_acct_root, $amy_acct )->{msg}, qr/gave order/i, "Give resources" );
        is( scalar( @{$amy->get_pending_orders()} ), 2, "second order" );
        like( $amy->new_order( { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() + 3 }, $amy_acct_root, $amy_acct )->{err}, qr/wrong turn/i, "Give resources for wrong turn" );
        like( $amy->new_order( { order => 'give_resources', amount => 3, recipient => $fred, turn => $turn->get_turn_number() - 1 }, $amy_acct_root, $amy_acct )->{err}, qr/wrong turn/i, "Give resources for wrong turn" );
        is( scalar( @{$amy->get_pending_orders()} ), 2, "no valid 3rd" );
        my $res = $amy->mark_as_ready( { ready => 1, turn => $turn->get_turn_number() + 1 } );
        like( $res->{err}, qr/Not on turn/i, "error message for ready for wrong turn" );

        is( $turn->get_turn_number(), 1, "turn number is 1" );
        is( $game->get_turn_number(), 1, "game turn number is 1" );

        # turn advance
        advance_turn( $turn );

        is( $turn->get_turn_number(), 2, "turn number is 2" );
        is( $game->get_turn_number(), 2, "game turn number is 2" );
        is( scalar( @{$game->get_turns()} ), 3, "Number of stored turns" );
        my $completed = $game->get_turns()->[2]->_players()->[0]->get_completed_orders();
        is( scalar( @$completed ), 2, "orders completed on this turn" );
        my $completed = $game->current_turn()->_players()->[0]->get_completed_orders();
        is( scalar( @$completed ), 2, "orders completed on this turn" );
        ok( $completed->[0]->get_resolution(), "first order ok" );
        ok( $completed->[1]->get_resolution(), "2nd order ok" );
        is( scalar( @{$game->get_turns()->[2]->_players()->[0]->get_pending_orders()} ), 0, "orders pending for this turn" );
        is( scalar( @{$game->get_turns()->[1]->_players()->[0]->get_pending_orders()} ), 2, "last turn pending" );

        is( scalar( @{$amy->get_completed_orders()} ), 2, "order reset with turn" );
        is( scalar( @{$amy->get_pending_orders()} ), 0, "order reset with turn" );

        is( $amy->get_resources(), 136, 'correct  resources after turn and give');
        is( $amy->get_tech_level(), 1, 'set up with correct tech level');
        is( $fred->get_resources(), 144, 'correct resources after turn and give');
        is( $fred->get_tech_level(), 1, 'set up with correct tech level');
#    }

    my $prototypes = $flav->get_ships();
    my( $scout_p, $boat_p, $dest_p, $cruis_p, $battleship_p ) = @$prototypes;

    # test build
#    {
        is( $scout_p->get_name(), 'Scout', "First ship is scout" );

        my $ord_req = $fred_sector->new_order( { turn => $turn->get_turn_number(),
                                                 order => "build",
                                                 ship  => $scout_p }, 
                                               $fred_acct_root, $fred_acct );
        my $ord = $ord_req->{r};
        ok( $ord, "Order submitted" );
        like( $ord_req->{msg}, qr/gave order/i, "scout ship order" );
        like( $fred_sector->new_order( { order => "build",
                                         turn  => 2,
                                         ship  => $battleship_p }, $fred_acct_root, $fred_acct )->{msg},
              qr/gave order/, " battleship build order" );
        like( $fred_sector->new_order( { order => "build",
                                         turn => $turn->get_turn_number(),
                                         ship  => $boat_p }, $fred_acct_root, $fred_acct )->{msg},
              qr/gave order/, " boat build order" );
    
        # turn advance
        advance_turn( $turn );

        is( $turn->get_turn_number(), 3, "turn number is 3" );
        is( $game->get_turn_number(), 3, "game turn number is 3" );
        my $completed = $game->current_turn()->_players()->[1]->get_sectors()->[0]->get_completed_orders();
        my $pending = $game->current_turn()->_players()->[1]->get_sectors()->[0]->get_pending_orders();
        is( scalar( @$completed ), 3, "build orders completed on this turn" );
        is( scalar( @$pending ), 0, "no pending orders after turn advance" );
        ok( $completed->[0]->get_resolution(), "build scout ok" );
        ok( $completed->[1]->get_resolution(), "build battleship ok" );
        ok( $completed->[2]->get_resolution(), "build boat ok" );
        my $player_ships = $fred->get_ships();
        my $sector_ships = $fred_sector->get_ships();
        is( @$player_ships, 3, "Player now as 3 ships" );
        is( @$sector_ships, 3, "Sector now as 3 ships" );
        my( $scout, $battleship, $boat ) = @$sector_ships;
#    }
    
    my $player_ships = $fred->get_ships();
    my $sector_ships = $fred_sector->get_ships();
    is( @$player_ships, 3, "Player now as 3 ships" );
    is( @$sector_ships, 3, "Sector now as 3 ships" );
    my( $scout, $battleship, $boat ) = @$sector_ships;
    
    my $links = $fred_sector->_links();
    is( @$links, 3, "three links from starting sector" );

    like( $battleship->new_order(
              {
                  from  => $fred_sector,
                  to    => $links->[0],
                  turn  => $turn->get_turn_number(),
                  order => 'move',
              }, $amy_acct_root, $amy_acct 
          )->{err}, qr/player may not order this/i, "Cannot order someone else's ship" );

    #
    # try to move scout into an unexplored sector and move it back.
    #
    my $ord_res = $scout->new_order(
              {
                  from  => $fred_sector,
                  to    => $links->[0],
                  turn  => $turn->get_turn_number(),
                  order => 'move',
              }, $fred_acct_root, $fred_acct 
        );
    like( $ord_res->{msg}, qr/gave order/i, "scout first order" );
    like( $scout->new_order(
              {
                  from  => $links->[0],
                  to    => $fred_sector,
                  turn  => $turn->get_turn_number(),
                  order => 'move',
              }, $fred_acct_root, $fred_acct 
          )->{msg}, qr/gave order/i, "scout second order" );
    
    #
    # try to move boat like a scout. it has more movement but should stop at the unexplored place.
    #
    like( $boat->new_order(
              {
                  from  => $fred_sector,
                  to    => $links->[2],
                  turn  => $turn->get_turn_number(),
                  order => 'move',
              }, $fred_acct_root, $fred_acct 
          )->{msg}, qr/gave order/i, "scout first order" );
    like( $boat->new_order(
              {
                  from  => $links->[2],
                  to    => $links->[0],
                  turn  => $turn->get_turn_number(),
                  order => 'move',
              }, $fred_acct_root, $fred_acct 
          )->{msg}, qr/gave order/i, "scout second order" );

    # turn advance

    advance_turn( $turn );


    ok( $boat->get_location()->is( $links->[2] ), "boat moved to correct place" );
    ok( $scout->get_location()->is( $fred_acct ), "scout moved then moved back home" );
    
    ok( $fred_chart->_has_entry( $fred_sector ), "fred knows own sector" );
    ok( ! $fred_chart->_has_entry( $amy_sector ), "fred doesn't know amy's sector" );
    ok( $fred_chart->_has_entry( $links->[2] ), "fred knows boat explored sector" );
    ok( $fred_chart->_has_entry( $links->[0] ), "fred knows scout explored sector" );
    ok( ! $fred_chart->_has_entry( $links->[1] ), "fred doesn't know unexplored sector" );

} #test_suite

sub advance_turn {
    my $turn = shift;
    my $players = $turn->_players();
    for my $p (@$players) {
        $p->mark_as_ready( { ready => 1, turn => $turn->get_turn_number() } );
    }
    for my $p (@$players) {
	print STDERR Data::Dumper->Dump(["COMPLETED",$p->get_all_completed_orders()]);
    }
} #advance_turn
