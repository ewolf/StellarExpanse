if( ! window[ 'se' ] ) { se = {}; }

se.refresh_chat = function() {
    var li = se_app.get_logged_in();
    var buf = "Who's logged in <ul>";	
    for( var i=0; i < li.length(); i++ ) {
	buf += '<li>' + li.get( i ) + '</li>';
    }
    buf += '</ul>' +
	'<div id="lobby_chat_messages_div">';

    var msgs = se_app.get_lobby_messages();
    var max = msgs.length();
    if( max > 15 ) { max = 15; }
    for( var i=0 ; i < max ; i++ ) {
	var msg = msgs.get( i );
	var dt = new Date( msg.get_time() * 1000 );
	dtxt = dt.getHours() + ':' + dt.getMinutes();
	buf += '<b>' + msg.get( 'author' ) + '</b> <span STYLE="font-size:small">' + dtxt + '</span>' +
	    ' : ' + msg.get( 'message' ) + '<BR>';
    }
    

    buf += '<input type="text" id="chat_msg"> <button type="Button" id="chat_b">Chat</button>' + 
	'</div>';

    $( '#lobby_chatter_div' ).empty().append( buf );

    $.yote.util.button_actions( {
	button : '#chat_b',
	texts  : [ '#chat_msg' ],
	action : function() {
	    se_app.message( $( '#chat_msg' ).val() );
	    console.log( [ se_app.get_lobby_messages()] );
	    se.refresh_chat();
	    $( '#chat_msg' ).focus();
	}
    } );
    
} //se.refresh_chat

/* SPLASH SCREEN ... entry point */
se.splash_screen = function( msg, first_time ) {
    $( '#header_bar' ).empty().append( "Welcome to Stellar Expanse" );
    var buf = '';
    if( $.yote.is_logged_in() ) {
	se_app.sync_lobby();
	$( '#main_div' ).removeClass( 'logged_out_div' );
	$( '#main_div' ).addClass( 'logged_in_div' );
	buf += '<div class="core" id="lobby_columns">' + 
	    '     <div class="panel core"><h2>You are in the lobby</h2></div>' + 
//	    '     <div class="core">' + 
	    '       <div id="lobby_div" class="column"></div>' + 
	    '       <div id="lobby_chatter_div" class="panel column"></div>' + 
	    '     </div>' + 
	    //	    '   </div>'
	    '';
	$( '#logged_in_status' ).empty().append( 
	    'Logged in as ' + se_app.account().get_login().get_handle() + '<BR><A href="#" id="logout">Log Out</A>'
	);
	$( '#logout' ).click( function() {
	    $.yote.logout();
	    $( '#header_bar' ).empty();
	    se.splash_screen( 'Logged Out');
	} );
    } else {
	$( '#main_div' ).addClass( 'logged_out_div' );
	$( '#main_div' ).removeClass( 'logged_in_div' );
	buf += '<div class="panel core" id="create_acct_div">' +
	    '<P><input type="text" id="username" placeholder="Name"><input type="password" placeholder="Password" id="pw"> <BUTTON type="BUTTON" id="log_in_b">Log In</BUTTON></P><BR>' +
	    'Create an Account' + 
	    '</div>';
	// start w/ being cleaned, coming to as if passed out, then flashback to revenge scene
    }
    
    $( '#main_div' ).empty().append( buf );

    if( $.yote.is_logged_in() ) {
	se.refresh_chat();
	var acct = se_app.account();
	se.to_game_login( acct.get_login(), acct, '', first_time );
    } else {
	$.yote.util.button_actions( {
	    button : '#log_in_b',
	    texts   : [ '#username', '#pw' ],
	    action : function() {
		$.yote.login( $( '#username' ).val(), $( '#pw' ).val(),
			      function( succ )  {
				  se.splash_screen("Logged in as '" + succ + "'")
			      },
			      function( err ) {
				  se.splash_screen(err);
			      } );
	    }
	} );
    }
} //se.splash_screen


se.to_game_login = function( login, acct, message, first_time ) {
    if( acct.get( 'Last_played' ) && first_time) {
	se.play_game( acct.get_Last_played(), acct );
	return;
    }
    var active_games  = acct.get_active_games();
    var pending_games = acct.get_pending_games();
    var avail_games   = se_app.available_games();
    msg( message );
    var update_text = '<div class="panel">';

    if( active_games.length() > 0 ) {
	var tab = $.yote.util.make_table('class="gametable"');
	tab.add_header_row( [ 'Game', 'Number of Players', 'Created By', 'On Turn', 'Play' ] );
	for( var i=0 ; i < active_games.length() ; i ++ ) {
	    var game = active_games.get( i );
	    tab.add_row( [ game.get_name(), game.get_number_players(), game.get_created_by().get_handle(), game.get_turn_number(), '<button type="button" id="play_' + game.id + '" class="btn btn-link">Play</button>' ] );
	}
	update_text += "<dl><dt>My Active Games</dt><tt>" + tab.get_html() + "</tt>";
    } //active games

    if( pending_games.length() > 0 ) {
	var tab = $.yote.util.make_table('class="gametable"');
	tab.add_header_row( [ 'Game', 'Joined Players', 'Created By', 'Leave' ] );
	for( var i=0 ; i < pending_games.length() ; i ++ ) {
	    var game = pending_games.get( i );
	    tab.add_row( [ game.get_name(), game.active_player_count() + " of " + game.get_number_players(), game.get_created_by().get_handle(), '<button type="button" id="leave_' + game.id + '" class="btn btn-link">Leave Game</button>' ] );
	}
	update_text += '</dl></div></div><div class="panel">' +
	    "    <dl><dt>Games waiting to start</dt><tt>" + tab.get_html() + "</tt>";
    } //pending games

    if( avail_games.length() > 0 ) {
	var tab = $.yote.util.make_table('class="gametable"');
	tab.add_header_row( [ 'Game', 'Joined Players', 'Starting Tech', 'Starting Resources', 'Created By', 'Join' ] );
	for( var i=0 ; i < avail_games.length() ; i ++ ) {
	    var game = avail_games.get( i );
	    tab.add_row( [ game.get_name(),
			   game.active_player_count() + " of " + game.get_number_players(),
			   game.get_starting_tech_level(),
			   game.get_starting_resources(),
			   game.get_created_by().get_handle(),
			   '<button type="button" id="join_' + game.id + '" class="btn btn-link">Join Game</button>'
			 ] );
	}
	update_text += '</dl></div><div class="panel">' +
	    "<dl><dt>Available Games</dt><tt>" + tab.get_html() + "</tt>";
    } //available games

    update_text += '</dl></div>';

    $( '#lobby_div' ).empty().append( update_text + '<div id="panel"><button id="newgame" type="button">New Game</button></div></div>' );

    // -------------   UI ADDED. NOW ATTACH EVENTS ---------

    for( var i=0 ; i < avail_games.length() ; i ++ ) {
	var g = avail_games.get( i );
	$( '#join_' + g.id ).click( (function( game, login, acct ) { return function() {
	    game.add_player( '', function(m) { se.to_game_login( login, acct, m ) },function(e){msg( e ) } );
	} } )( g, login, acct ) );
    }

    for( var i=0 ; i < active_games.length() ; i ++ ) {
	var g = active_games.get( i );
	$( '#play_' + g.id ).click( (function( game, acct ) { return function() {
	    se.play_game( game, acct );
	} } )( g, acct ) );
    }

    if( pending_games.length() > 0 ) {
	for( var i=0 ; i < pending_games.length() ; i ++ ) {
	    var g = pending_games.get( i );
	    $( '#leave_' + g.id ).click( (function( game, login, acct ) { return function() {
		game.remove_player('',function(m){ se.to_game_login( login, acct, m ) },function(e){ msg( e ) });
	    } } )( g, login, acct ) );
	}
    }


    $( '#newgame' ).click(function() {
	update_text = '<h2>Create New Game</h2>';
	var tab = $.yote.util.make_table();
	var flavors = se_app.get_flavors();
	tab.add_param_row( [ 'Name', '<input type="text" id="game_name_fld">' ] );
	if( flavors.length() > 1 ) {
	    var sel_text = '<select id="flavor_sel">';
	    if( flavors.length() > 1 ) {
		for( var i=0; i<flavors.length(); ++i ) {
		    var flav = flavors.get(i);
		    sel_text += '<option value="' + i + '">' + flav.get_name() + '</option>';
		}
	    }
	    tab.add_param_row( [ 'Flavor', sel_text + '</select>' ] );
	} else {
	    var fl = flavors.get(0);
	    tab.add_param_row( [ 'Flavor', '<span>' + fl.get_name() +
				 '</span><input type="hidden" id="flavor_sel" value="0">' ] );

	}
	var player_sel = '<select id="player_sel">';
	for( var i=1; i < 9; i++ ) {
	    player_sel += '<option value="' + i + '">' + i + '</option>';
	}
	tab.add_param_row( [ 'Number of Players', player_sel + '</select>' ] );
	var tech_sel = '<select id="tech_sel">';
	for( var i=1; i < 5; i++ ) {
	    tech_sel += '<option value="' + i + '">' + i + '</option>';
	}
	tab.add_param_row( [ 'Starting Tech Level', tech_sel + '</select>' ] );
	tab.add_param_row( [ 'Starting Resources', '<input type="text" id="resource_fld">' ] );
	update_text += tab.get_html() + '<BR><button type="button" id="create_game" class="btn disabled btn-link">Create</button>' +
	    '<button class="btn btn-link" type="button" id="cancel_new">Cancel</button>';


	$( '#lobby_div' ).empty().append( update_text );
	$( '#cancel_new' ).click( function() {
	    se.to_game_login( acct.get_login(), acct, '' );
	} );

	$( '#game_name_fld,#resource_fld' ).keyup(function() {
	    if( $( '#game_name_fld' ).val() && $( '#resource_fld' ).val() > 0 ) {
		$( '#create_game' ).removeClass( 'disabled' );
	    } else {
		$( '#create_game' ).addClass( 'disabled' );
	    }
	} );
	$( '#create_game' ).click( function() {
	    se_app.create_game(
		{
                    name:$('#game_name_fld').val(),
                    number_players:$('#player_sel').val(),
		    starting_resources:$('#resource_fld').val(),
		    starting_tech_level:$('#tech_sel').val(),
		    flavor:flavors.get($('#flavor_sel').val())
		},
		function( msg ) {
		    se.to_game_login( login, acct, msg );
		},
		function( err ) {
		    msg( err );
		}
	    );
	} );
    });


} //se.to_game_login
