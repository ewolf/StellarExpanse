if( ! window[ 'se' ] ) { se = {}; }

se.gameboard = undefined;

se.play_game = function ( game, acct ) {
    /* sections :
       news
       game information/turn information
       systems panel
       detail of a system in systems panel ( indicate presence of  foe or our ships  )
       'subway map' of systems within reach of this one
       'build controls'
       exploration panel
       list of sectors not controlled but with our ships there
       ships panel
       table of ours ships, showing sector, orders, etc
       order summary
    */
    if( acct.get_Last_played() != game ) {
	acct._send_update( { Last_played : game } );
    }
    var game_name  = game.get_name();
    var on_turn    = game.get_turn_number();
    var players    = game.current_players();
    var player     = game.my_player();    // player -> handle
    player.load_data();
    var my_sectors = player.get_sectors();
    var my_ships   = player.get_ships();
    var starchart  = player.get_starchart();
    var map        = starchart.get_map(); //hash of sector id -> star chart node

    $( '#main_div' ).addClass( 'in_game_div' );
    $( '#main_div' ).removeClass( 'logged_in_div' );

    var update_text = '<div class="core">\
 <div id="side_summary" class="column">\
  <DIV class="panel">\
   <A HREF="#" id="refresh">Refresh Page</A>\
   <h2>' + game_name + '</h2>\
   Turn ' +  on_turn  + '<BR>\
   <a href="#" id="back_to_lobby">Back To Lobby</a>\
  </div>\
  <DIV class="sidenav panel">\
    <UL>\
     <LI id="sys_com"><label for="go_systems">Systems</label></LI>\
     <LI id="sys_com"><label for="go_shipt">Ships</label></LI>\
     <LI id="msg_com"><label for="go_messages">Turn Messages</label></LI>\
     <LI id="sel_com"><label for="go_comm">Communications</label></LI>\
    </UL>\
   <UL>\
  </div>\
  <DIV class="panel centered">\
   <BUTTON class="not_ready" type="BUTTON" id="set_ready">Not Ready</BUTTON>\
  </DIV>\
 </div>\
 <div id="system_panel" class="column debug panel">\
    </div>\
</div>\
    ';
    update_text +=
	'<BR>' +
	'<dt>Players</dt><dd><ul id="playerslist">';

    var pkeys = players.keys();
    for( var i=0; i < pkeys.length; i++ ) {
	update_text += '<li>' + pkeys[ i ] + '</li>';
    }
    update_text += '</ul></dd>';

    function enemy_ship( ene ) {
	return ene.get_name();
    }

    function my_ship( shp ) {
	return shp.get_name();
    }


    if( on_turn > 0 ) {
	update_text += '<dt>Last Turn Orders</dt>' +
	    '<dd><ul>';
	var lto = player.get_all_completed_orders().get( on_turn );
	if( lto ) {
	    for( var i=0; i < lto.length(); i++ ) {
		var ord = lto.get( i );
		if( ord.get_order() == 'build' ) {
		    update_text += '<li>' + ord.get_resolution_message() + '</li>';
		} else {
		    update_text += '<li>' + ord.get_resolution_message() + '</li>';
		}
	    }
	}
	update_text += '</ul>';
    }

    update_text += '</tt>';

    update_text +=  '<dt>resource units</dt><tt>' + player.get_resources() + '</tt>';

    update_text += '</tt>';

    //make a subway map of explored sectors. note if there are unexplored ends, and the connections this sector has.

    var my_discovered_tab = $.yote.util.make_table( 'border=1' );
    my_discovered_tab.add_header_row( [ 'Sector', 'Links' ] );

    var my_sector_tab = $.yote.util.make_table( 'border=1' );
    my_sector_tab.add_header_row( [ 'Sector', 'Links' ] );

    var my_fleet_tab = $.yote.util.make_table( 'border=1' );
    my_fleet_tab.add_header_row( [ 'Sector', 'Links' ] );

    my_sector_ids = {};
    for( var i=0 ; i < my_sectors.length() ; i++ ) {
	var sec = my_sectors.get( i );
	my_sector_ids[ sec.id ] = sec;
	var links = sec.get_links();
	var keys = links.keys();
	var linktxt = '<ul>';
	for( var j=0 ; j < keys.length; j++ ) {
	    linktxt += '<li>' + links.get( keys[ j ] ).get_name() + '</li>';
	}
	linktxt += '</ul>';
	my_sector_tab.add_row( [ '<a href="#" id="sector_' + sec.id + '">' + sec.get_name() + '</a>', linktxt ] );
    }
    var nodeid2ships = {};
    var nodeid2node = {};
    for( var i=0 ; i < my_ships.length(); i++ ) {
	var ship = my_ships.get( i );
	var loc = ship.get_location();
	var node = map.get( loc.id );
	if( node ) {
	    nodeid2node[ node.id ] = node;
	    if( typeof nodeid2ships[ node.id ] === 'undefined' ) {
		nodeid2ships[ node.id ] = { my : [], enemy : [] };
	    }
	    nodeid2ships[ node.id ][ 'my' ].push( ship );
	}
    } //each ship
    var sectorids = map.keys();
    var nodes = [];
    for( var i=0; i < sectorids.length; i++ ) {
	var node = map.get( sectorids[i] );
	if( node.get_discovered() == '1' && ! ( sectorids[ i ] in my_sector_ids )) {
	    // need to weed out owned vs discovered nodes
	    // my_sectors

	    var links = node.get_links();
	    var keys = links.keys();
	    var linktxt = '<ul>';
	    for( var j=0 ; j < keys.length; j++ ) {
		linktxt += '<li>' + links.get( keys[ j ] ).get_name() + '</li>';
	    }
	    linktxt += '</ul>';
	    my_discovered_tab.add_row( [ '<a href="#" id="node_' + node.id + '">' + node.get_name() + '</a>', linktxt ] );
	    nodes.push( node );
	}

	// also need to check the node that is in nodeid2ships to see if there are enemy ships there
	// just pull in all ships from the sector
	if( node.id in nodeid2ships || sectorids[i] in my_sector_ids ) {
	    var node_enemies = starchart.enemy_ships( sectorids[ i ] );
	    for( var j=0; j < node_enemies.length(); j++ ) {
		nodeid2ships[ node.id ][ 'enemy' ].push( node_enemies.get( j ) );
	    }
	}
    } //each sector

    for( var nid in nodeid2ships ) {
	var node = nodeid2node[ nid ];
	var links = node.get_links();
	var keys = links.keys();
	var linktxt = '<ul>';
	for( var j=0 ; j < keys.length; j++ ) {
	    linktxt += '<li>' + links.get( keys[ j ] ).get_name() + '</li>';
	}
	linktxt += '</ul>';
	my_fleet_tab.add_row( [ '<a href="#" id="shipnode_' + node.id + '">' + node.get_name() + '</a>', linktxt ] );
    }

    update_text += '<dt>My Sectors</dt><dd>' + my_sector_tab.get_html() + '</dd>' +
	'<dt>Fleet Locations</dt><dd>' + my_fleet_tab.get_html() + '</dd>' +
	'<dt>Explored Sectors</dt><dd>' + my_discovered_tab.get_html() + '</dd>' +
	'</div><div class="span8" ><div id=sector_panel>';

    update_text += '</div><div id=fleet_panel>';
    update_text += '</dl><BR>';

    update_text += '</div>';

    function make_ship_fire_orders( shp, enemies ) {
	function add_fire_order( div, ship, targs, o_idx, existing_order ) {
	    // existing order has order='fire', beams, and target
	    var txt = 'beams : <SELECT id="ships_beams_' + ship.id + '_' + o_idx + '">';
	    var beams = shp.get_attack_beams();
	    for( var i=0; i <= beams; i++ ) {
		if( existing_order && existing_order.get_Beams() == i ) {
		    txt += '<option selected value="' + i + '">' + i + '</option>';
		} else {
		    txt += '<option value="' + i + '">' + i + '</option>';
		}
	    }
	    txt += '</select>';
	    txt += 'Target : <SELECT id="ships_targets_' + ship.id + '_' + o_idx + '">';

	    var enhash = {};
	    for( var j=0; j < enemies.length ; j++ ) {
		var en = enemies[ j ];
		enhash[ en.id ] = en;
		if( existing_order && en.equals( existing_order.get_Target() ) ) {
		    txt += '<option SELECTED value="' + en.id + '">' + enemy_ship( en ) + ' (' + en.get_owner().get_name() + ")</option>";
		} else {
		    txt += '<option value="' + en.id + '">' + enemy_ship( en ) + ' (' + en.get_owner().get_name() + ")</option>";
		}
	    }
	    txt += '</select>';

	    $( div ).append( txt );

	    function bind_select( dv, shp, odx, ene, ens, ex_ord ) {
		$( '#ships_beams_' + shp.id + '_' + odx ).unbind();
		$( '#ships_targets_' + shp.id + '_' + odx ).unbind();

		$( '#ships_beams_' + shp.id + '_' + odx ).change(function() {
		    if( ex_ord ) {
			var bchange = $( '#ships_beams_' + shp.id + '_' + odx ).val();
			if( bchange != '0' ) {

			    // THE BIG DEAL is that only capitalized keys get any love.
			    // might have to change the keynames here, or just remove and recreate the order

			    ex_ord.set_Beams( $( '#ships_beams_' + shp.id + '_' + odx ).val() );
			} else {
			    shp.remove_order( ex_ord );
			    $( '#ships_beams_' + shp.id + '_' + odx ).remove();
			    $( '#ships_targets_' + shp.id + '_' + odx ).remove();
			    //put a bind function here
			}
		    } else {
			var fire_ord = shp.new_order( {
			    order  : 'fire',
			    turn   : on_turn,
			    Target : ens[ $( '#ships_targets_' + shp.id + '_' + odx ).val() ],
			    Beams  : $( '#ships_beams_' + shp.id + '_' + odx ).val()
			} );
			bind_select( dv, shp, odx, ene, ens, fire_ord );
			// should only add if there are more targets
			add_fire_order( dv, shp, ene, odx + 1 );
		    }
		} );
		$( '#ships_targets_' + shp.id + '_' + odx ).change(function() {
		    if( ex_ord ) {
			ex_ord.set_Target( ens[ $( '#ships_targets_' + shp.id + '_' + odx ).val() ] );
		    }
		} );
	    } //bind_select

	    bind_select( div, ship, o_idx, enemies, enhash, existing_order );

	} //add_fire_order

	var beams = shp.get_attack_beams();

	if( beams > 0 ) {
	    $( '#ship_' + shp.id + '_attack_target_div' ).empty();
	    var ords = shp.get_pending_orders();
	    var fire_idx = 0;
	    for( var i=0; i < ords.length(); i++ ) {
		var ord = ords.get( i );
		if( ord.get_order() == 'fire' ) {
		    add_fire_order( '#ship_' + shp.id + '_attack_target_div' , shp, enemies, fire_idx, ord );
		    fire_idx++;
		}
	    }
	    add_fire_order( '#ship_' + shp.id + '_attack_target_div', shp, enemies, fire_idx );
	} //if there are beams
    } //make_ship_fire_orders

    function make_ship_carrier_orders( shp, m_ships ) {
	var rs = shp.get_racksize() * 1;
	if( rs > 0 ) {
	    var buf = '';
	    var include = false;

	    var carried = shp.get_carried();
	    if( carried.length() > 0 ) {
		for( var i=0; i < carried.length(); i++ ) {
		    var car = carried.get( i );
		    var ords = car.get_pending_orders();
		    var is_unloading = false;
		    for( var j=0; j < ords.length(); j++ ) {
			if( ords.get( j ).get_order() == 'unload' ) {
			    is_unloading = true;
			}
		    }
		    if( is_unloading ) {
			buf += 'Unloading ' + my_ship( car ) +
			    ' <BUTTON TYPE="BUTTON" id="remove_unload_' + car.id + '">cancel</button><BR>';
		    } else {
			buf += '<button type="button" id="unload_' + car.id +
			    '">Unload ' + my_ship( car ) + '</button><br>';
		    }
		    include = true;
		}
	    }
	    for( var i=0; i < m_ships.length; i++ ) {
		var m_ship = m_ships[ i ];
		if( m_ship.get_size() <= rs ) {
		    var c_ords = m_ship.get_pending_orders();
		    var is_loading = false;
		    for( var j=0; j < c_ords.length(); j++ ) {
			if( c_ords.get( j ).get_order() == 'load' && c_ords.get( j ).get_carrier().equals( shp ) ) {
			    is_loading = true;
			}
		    }
		    if( is_loading ) {
			buf += 'Loading ' + my_ship( m_ship ) + ' <BUTTON TYPE="BUTTON" id="remove_load_'
			    + shp.id + '_' + m_ship.id + '">cancel</button><BR>';
		    } else {
			buf += '<button id="load_' + shp.id + '_' + m_ship.id +
			    '" type="button">Load ' + my_ship( m_ship ) + '</button><br>';
		    }
		    include = true;
		}
	    }

	    if( include ) {
		$( '#ship_' + shp.id + '_carrier_cmd_div' ).empty().append( buf );

		if( carried.length() > 0 ) {
		    for( var i=0; i < carried.length(); i++ ) {
			var c = carried.get( i );
			var unloading_order = false;
			for( var j=0; j < ords.length(); j++ ) {
			    if( ords.get( j ).get_order() == 'unload' ) {
				unloading_order = ords.get( j );
			    }
			}
			$( '#unload_' + c.id ).click( (function(cc,ss){ return function() {
			    cc.new_order( {
				order : 'unload',
				turn  : on_turn
			    } );
			    make_ship_carrier_orders( ss, m_ships );
			} } ) ( c, shp ) );
			if( unloading_order ) {
			    $( '#remove_unload_' + c.id ).click( (function(cc,ss,uo){ return function() {
				cc.remove_order( uo );
				make_ship_carrier_orders( ss, m_ships );
			    } } ) ( c, shp, unloading_order ) );
			}
		    }
		}
		for( var i=0; i < m_ships.length; i++ ) {
		    var m_ship = m_ships[ i ];
		    if( m_ship.get_size() <= rs ) {
			var loading_order = false;
			for( var j=0; j < c_ords.length(); j++ ) {
			    if( c_ords.get( j ).get_order() == 'load' && c_ords.get( j ).get_carrier().equals( shp ) ) {
				loading_order = c_ords.get( j );
			    }
			}
			$( '#load_' + shp.id + '_' + m_ship.id ).click( (function(cs,s){ return function() {
			    s.new_order( {
				order    : 'load',
				carrier  : cs,
				turn     : on_turn
			    } );
			    make_ship_carrier_orders( cs, m_ships );
			} } )( shp, m_ship ) );
			if( loading_order ) {
			    $( '#remove_load_' + shp.id + '_' + m_ship.id ).click( (function(cs,s,lo){ return function() {
				s.remove_order( lo );
				make_ship_carrier_orders( cs, m_ships );
			    } } )( shp, m_ship, loading_order ) );
			}
		    }
		}
	    }
	}
    } //make_ship_carrier_orders

    function make_ship_move_orders( shp ) {
	var jumps = shp.get_jumps();
	if( jumps > 0 ) {
	    var ords = shp.get_pending_orders();
	    var move_ords = [];
	    for( var i=0; i < ords.length(); i++ ) {
		var ord = ords.get( i );
		if( ord.get_order() == 'move' ) {
		    move_ords.push( ord );
		}
	    }

	    var buf = '';
	    var sec = shp.get_location();
	    var cancel_ord = null;
	    for( var i=0; i < move_ords.length; i++ ) {
		var ord = move_ords[i];
		sec = ord.get_to();
		buf += sec.get_name();
		jumps--;
		if( i == move_ords.length - 1 ) {
		    //last one
		    cancel_ord = ord;
		    buf += '<button id="cancel_move_' + ord.id + '" type="button" class="btn btn-link">Remove</button>';
		}
		buf += '<BR>';
	    }
	    if( jumps > 0 ) {
		var links = sec.get_links();
		var lkey = links.keys();
		buf += '<select id="ship_' + shp.id + '_move_sel"><option value=0>none</option>';
		for( var i=0; i< lkey.length; i++ ) {
		    if( map.get( lkey[ i ] ) ) {
			var link_sect = links.get( lkey[ i ] );
			buf += '<option value="' + link_sect.id + '">' + link_sect.get_name() + '</option>';
		    }
		}
		buf += '</select>'
	    }
	    $( '#ship_' + shp.id + '_move_div' ).empty().append( buf );
	    if( cancel_ord != null ) {
		(function( co, s ) {
		    $( '#cancel_move_' + co.id ).click(function() {
			s.remove_order( co );
			make_ship_move_orders( s );
		    } );
		} )( cancel_ord, shp );
	    }
	    $( '#ship_' + shp.id + '_move_sel' ).change(function() {
		if( $( this ).val() == 0 ) {
		    //0 so do nothing
		    return;
		}
		shp.new_order( {
		    order : 'move',
		    turn : on_turn,
		    from : sec,
		    to : links.get( $( this ).val() )
		} );
		make_ship_move_orders( shp );
	    } );
	} //if ship has more than one jump
    } //make_ship_move_orders

    function show_sector( sector, node, player, fleets ) {
	if( ! sector ) { return }
	var stext = '';

	var tab = $.yote.util.make_table();
	if( sector ) {
	    tab.add_param_row( [ 'name', sector.get_name() ] );
	    tab.add_param_row( [ 'production', sector.get_currprod() + ' of ' + sector.get_maxprod() ] );
	    tab.add_param_row( [ 'build capacity', sector.get_buildcap() ] );
	} else {
	    tab.add_param_row( [ 'name', node.get_name() ] );
	    tab.add_param_row( [ 'production ', node.get_seen_production() + ' / ' + node.get_seen_max_production() ] );
	}

	var ltxt = '<ul>';
	var links = node.get_links();
	var lkeys = links.keys();
	for( var i=0; i<lkeys.length; i++ ) {
	    var link_sect = links.get( lkeys[ i ] );
	    ltxt += '<li>' + link_sect.get_name() + '</li>';
	}
	ltxt += '</ul>';
	// build a graph of things within 4 of the node
	if( se.gameboard != undefined ) {
	    se.gameboard.hide();
	}
	se.gameboard = se.graph();
	var to_graph = {};
	var seen     = {};
	var round = [ node ]; // list of nodes to use for next layer
	for( var i=0; i < 4; i++ ) { //the 4 layers
	    var next_round = {};
	    for( var j=0; j < round.length; j++ ) {
		var round_node  = round[ j ];
		if( round_node.get_links ) {
		    if( ! (round_node.id in seen) ) {
			seen[ round_node.id ] = 1;
			var node = se.gameboard.node( round_node.get_name(), round_node.id, round_node );
			(function( rn ) { node.map_node = rn; } )( round_node );
		    }
		    var round_links = round_node.get_links();
		    var r_keys      = round_links.keys()
		    for( var k=0; k < r_keys.length; k++ ) {
			var x_node = round_links.get( r_keys[ k ] );
			if( ! ( x_node.id in seen ) ) {
			    seen[ x_node.id ] = 1;
			    var node = se.gameboard.node( x_node.get_name(), x_node.id, x_node );
			}
			se.gameboard.link( round_node.id, x_node.id );
			next_round[ x_node.id ] = x_node;
		    }
		}
	    }
	    round = [];
	    for( var j in next_round ) {
		round.push( next_round[ j ] );
	    }
	} // the four layers


	tab.add_param_row( [ 'Links', ltxt ] );

	var my_ships = fleets[ 'my' ];
	var other_ships = fleets[ 'enemy' ];


	var header_row = [ 'Ship', 'Move Orders' ];

	// check if there are carriers here
	var has_carriers = false;
	for( var i=0; i < my_ships.length; i++ ) {
	    if( my_ships[ i ].get_racksize() * 1 > 0 ) {
		has_carriers = true;
	    }
	}
	if( has_carriers ) {
	    header_row.push( 'Carrier Commands' );
	}

	if( other_ships.length > 0 ) {
	    header_row.push( 'Attack Target' );
	}

	var ship_tab = $.yote.util.make_table( 'border=1' );
	ship_tab.add_header_row( header_row );

	for( var i=0; i < my_ships.length; i++ ) {
	    var ship = my_ships[ i ];
	    // name, move, fire
	    var ship_tab_row = [ my_ship( ship ), '<div id="ship_' + ship.id + '_move_div">No Move</div>' ];
	    if( has_carriers ) {
		ship_tab_row.push( '<div id="ship_' + ship.id + '_carrier_cmd_div">N/A</div>' );
	    }

	    if( other_ships.length > 0 ) {
		ship_tab_row.push('<div id="ship_' + ship.id + '_attack_target_div">No Target</div>');
	    }
	    ship_tab.add_row( ship_tab_row );
	}

	if( my_ships.length > 0 ) {
	    tab.add_param_row( [ 'my ships', ship_tab.get_html() ] );
	}
	if( other_ships.length > 0 ) {
	    var e_stxt = '<ul>';
	    for( var i=0; i < other_ships.length; i++ ) {
		var ship = other_ships[ i ];
		e_stxt += '<li>' + my_ship( ship ) + ' (' + ship.get_owner().get_name() + ')</li>';
	    }
	    e_stxt  += '</ul>';
	    tab.add_param_row( [ 'enemy ships', e_stxt ] );
	}

	// build orders here
	// what to build, the quantity to build
	// collect in an order, with a pending available credit

	tab.add_param_row( [ 'pending orders', '<div id="pending_orders_div"><ul id="pending_orders_ul"></ul></div>' ] );
	function add_to_pending_build_orders( order, sector ) {
	    var ship = order.get_ship();
	    var quan = order.get_quantity();
	    if( quan == 1 ) {
		$( '#pending_orders_ul' ).append( '<li>Build one ' + ship.get_name() + ' <button type="button" class="btn btn-link" id="cancel_order_' + order.id + '">Cancel</button></li>' );
	    } else {
		$( '#pending_orders_ul' ).append( '<li>Build ' + quan + ' ' + ship.get_name() + 's <button type="button" class="btn btn-link" id="cancel_order_' + order.id + '">Cancel</button></li>' );
	    }
	    (function(ord,sec) {
		$( '#cancel_order_' + ord.id ).click( function() {
		    sec.remove_order( ord );
		    show_all_pending_orders( sec );
		} );
	    } )( order, sector );
	} //add_to_pending_build_orders


	stext += '<div id="canvas"></div>' + tab.get_html();

	if( sector ) {
	    var can_bld = sector.can_build_items();
	    var can_bld_k = can_bld.keys();


	    stext += '<dl><dt>Build</dt><dd>';

	    var tab = $.yote.util.make_table('border=1');
	    tab.add_header_row( [ 'Ship', 'Quantity', 'Build' ] );
	    for( var i=0; i<can_bld_k.length; i++ ) {
		var item = can_bld.get( can_bld_k[ i ] );
		var max_quan =  parseInt( player.get_resources() / item.get_cost() );
		if( max_quan > 0 ) {
		    var txt = '';
		    if( item.get_type() == 'TECH' || max_quan == 1 ) {
			txt = '1<input type="hidden" value="1" id="quan_' + item.id + '">';
		    } else {
			txt += '<select id="quan_' + item.id + '">';
			for( var j=1; j <= max_quan ; j++ ) {
			    txt += '<option value="' + j + '">' + j + '</option>';
			}
			txt += '</select>';
		    }
		    tab.add_param_row( [ item.get_name(), txt, '<button id="buy_' + item.id  + '" type="button">Place Order</button>' ] );
		} else {
		    tab.add_param_row( [ item.get_name(), 'n/a', 'Not enough resources' ] );
		}
	    }

	    stext += tab.get_html() + '</dd></dl>';
	}
	$( '#sector_panel' ).empty().append( stext );


	for( var i=0; i < my_ships.length; i++ ) {
	    var ship = my_ships[ i ];
	    make_ship_move_orders( ship );
	    make_ship_fire_orders( ship, other_ships );
	    make_ship_carrier_orders( ship, my_ships );
	}

	function show_all_pending_orders( sec ) {
	    var pending_build_orders = sec.get_pending_orders();
	    $( '#pending_orders_ul' ).empty();
	    if( pending_build_orders.length() > 0 ) {
		for( var i=0; i < pending_build_orders.length(); i++ ) {
		    var ord = pending_build_orders.get( i );
		    if( ord.get_order() == 'build' ) {
			add_to_pending_build_orders( ord, sec );
		    }
		}
	    }
	} //show_all_pending_orders

	if( sector ) {
	    show_all_pending_orders( sector );

	    for( var i=0; i<can_bld_k.length; i++ ) {
		(function( item, sec ) {
		    $( '#buy_' + item.id ).click( function() {
			add_to_pending_build_orders( sec.new_order( {
			    order : 'build',
			    turn  : on_turn,
			    ship  : item,
			    quantity : $( '#quan_' + item.id ).val()
			} ), sec );
		    } )
		} )( can_bld.get( can_bld_k[ i ] ), sector );
	    }
	}

	var p = se.gameboard.draw( 350, 35, 800, 400 );

	// now need to make some 'shopping cart' logic that holds onto build and other orders

	// a polling to see what's changed
	if( game_check_interval ) {
	    clearInterval( game_check_interval );
	}
	game_check_interval = setInterval(
	    function() {
		acct.sync_all();
		if( game.get_turn_number() > on_turn ) {
		    se.play_game( game, acct );
		    msg( "The Turn Advanced to " + game.get_turn_number() );
		}
	    }, 40000 );

    } //show_sector

    $( '#main_div' ).empty().append( update_text );
    var lsect = my_sectors.get( 0 );
    if( player.get( 'Last_sector' ) ) {
	lsect = player.get_Last_sector();
    }
    var last_node = map.get( lsect.id );
    show_sector( lsect, last_node,  player, nodeid2ships[ last_node.id ] || { my : [], enemy : [] }  );

    // ------- define listeners

    $( "#set_ready" ).click( function() {
	if( $( this ).hasClass( 'ready' ) ) { // changing from ready to not_ready
	    var turn_now = player.mark_as_ready( {
		turn  : on_turn,
		ready : 0,
	    } );
	    $( this ).removeClass( 'ready' );
	    $( this ).addClass( 'not_ready' );
	    $( this ).empty().append( 'Not Ready' );
	} else { //changing from not_ready to ready
	    var turn_now = player.mark_as_ready( {
		turn  : on_turn,
		ready : 1,
	    } );	    
	    if( turn_now > on_turn ) {
		se.play_game( game, acct ); 
	    } else {
		$( this ).addClass( 'ready' );
		$( this ).removeClass( 'not_ready' );
		$( this ).empty().append( 'Ready' );
	    }
	}

    } );


    /*  ***** SECTOR LINKS ******* */
    for( var i=0; i < my_sectors.length(); i++ ) {
	var sec = my_sectors.get( i );
	(function( s ) {
	    $( '#sector_' + s.id ).click(function() {
		var nd = map.get( s.id );
		show_sector( s, nd, player, nodeid2ships[ nd.id ] || { my : [], enemy : [] } );
	    } );
	} )( sec );
    }
    /*  ***** NODE LINKS ******* */

    for( var i=0; i < sectorids.length; i++ ) {
	var s_id = sectorids[ i ];
	var n = map.get( s_id );
	if( s_id in my_sector_ids ) {
	    (function (sec,nod) {
		console.log("n1", sec, nod);
		$( '#node_' + nod.id ).click( function() {
		    show_sector( sec, nod, player, nodeid2ships[ nod.id ] || { my : [], enemy : [] } );
		} )
		$( '#shipnode_' + nod.id ).click( function() {
		    show_sector( sec, nod, player, nodeid2ships[ nod.id ] || { my : [], enemy : [] } );
		} )
	    })( my_sector_ids[ s_id ],n );
	}
	else {
	    if( node.get_discovered() == '1' ) {
		(function (node) {
   	  	    console.log("n2", node);
		    $( '#node_' + node.id ).click( function() {
			show_sector( false, node, player, nodeid2ships[ node.id ] || { my : [], enemy : [] } );
		    } );
		    $( '#shipnode_' + node.id ).click( function() {
			show_sector( false, node, player, nodeid2ships[ node.id ] || { my : [], enemy : [] } );
		    } );

		})( n );
	    }
	}
    }



    $( '#back_to_lobby' ).click( function() {
	if( se.gameboard != undefined ) {
	    se.gameboard.hide();
	}
	acct._send_update( { Last_played : '' } );
	se.splash_screen();
    } );

    $( '#refresh' ).click(function() {
	console.log( game );
	game.refresh();
	se.play_game( game, acct );
    } );

    // subway map?
    /*
      gamma --\
      \
      alpha -- beta -- omega -- iota
      \
      \-- zeta
    */

};  // play game

se.to_game_login = function( login, acct, message, first_time ) {
    if( acct.get( 'Last_played' ) && first_time) {
	play_game( acct.get_Last_played(), acct );
	return;
    }
    var active_games  = acct.get_active_games();
    var pending_games = acct.get_pending_games();
    var avail_games   = se_app.available_games();
    msg( message );
    var update_text = '<div class="container">' +
	'<div class="row">' +
	' <div class="span11 offset1">' +
	'  The Lobby ' +
	' </div>' +
	'</div>' +
	'<div class="row">' +
	' <div class="span11 offset1">';

    if( active_games.length() > 0 ) {
	var tab = $.yote.util.make_table('class="gametable"');
	tab.add_header_row( [ 'Game', 'Number of Players', 'Created By', 'On Turn', 'Play' ] );
	for( var i=0 ; i < active_games.length() ; i ++ ) {
	    var game = active_games.get( i );
	    tab.add_row( [ game.get_name(), game.get_number_players(), game.get_created_by().get_handle(), game.get_turn_number(), '<button type="button" id="play_' + game.id + '" class="btn btn-link">Play</button>' ] );
	}
	update_text += "<dl><dt>Active Games</dt><tt>" + tab.get_html() + "</tt>";
    } //active games

    if( pending_games.length() > 0 ) {
	var tab = $.yote.util.make_table('class="gametable"');
	tab.add_header_row( [ 'Game', 'Joined Players', 'Created By', 'Leave' ] );
	for( var i=0 ; i < pending_games.length() ; i ++ ) {
	    var game = pending_games.get( i );
	    tab.add_row( [ game.get_name(), game.active_player_count() + " of " + game.get_number_players(), game.get_created_by().get_handle(), '<button type="button" id="leave_' + game.id + '" class="btn btn-link">Leave Game</button>' ] );
	}
	update_text += '</dl></div></div><div class="row">' +
	    ' <div class="span11 offset1">' +
	    "    <dl<dt>Games waiting to start</dt><tt>" + tab.get_html() + "</tt>";
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
	update_text += '</dl></div></div><div class="row">' +
	    ' <div class="span11 offset1">' +
	    "<dl><dt>Available Games</dt><tt>" + tab.get_html() + "</tt>";
    } //available games

    update_text += '</dl></div></div>';

    $( '#lobby_div' ).empty().append( update_text + '<div id="row"><div class="span11 offset1"><button id="newgame" type="button">New Game</button></div></div></div>' );

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
	    play_game( game, acct );
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
	update_text = '<button class="btn btn-link" type="button" id="back_to_lobby">Back to the Lobby </button><h2>Create New Game</h2>';
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
	update_text += tab.get_html() + '<BR><button type="button" id="create_game" class="btn disabled btn-link">Create</button>';


	$( '#lobby_div' ).empty().append( update_text );
	$( '#back_to_lobby' ).click( function() {
	    acct._send_update( { Last_played : '' } );
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
