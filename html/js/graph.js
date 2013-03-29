function graph() {
    return {
	_next_node_id : 0,
	nodes     : {},
	distances : {},
	matrix    : undefined,
	placed    : undefined,
	mkey      : {},
	set       : undefined,
	node      : function( name, data ) {
	    var newid = this._next_node_id++;
	    var nd = { name  : name, 
		       data  : data, 
		       drawn : false,
		       links : {}, id : newid, 
		       graphics : { links : {}, self : []  } };
	    this.nodes[ newid ] = nd;
	    return nd;
	},
	link      : function( a, b ) {
	    this.nodes[ a ].links[ b ] = this.nodes[ b ];
	    this.nodes[ b ].links[ a ] = this.nodes[ a ];
	},
	remove_node : function( node_id ) {
	    // remove link lines
	    var node = this.nodes[ node_id ];
	    var linkids = Object.keys( node.links );
	    for( var i=0; i < linkids.length; i++ ) {
		var lnk = node.links[ linkids[ i ] ];
		for( var j=0; j < lnk.graphics[ 'links' ][ node_id ].length; j++ ) {
		    var gr = lnk.graphics[ 'links' ][ node_id ][ j ];
		    this.set.exclude( gr );
		    gr.hide();
		}
		for( var j=0; j < node.graphics[ 'links' ][ lnk.id ].length; j++ ) {
		    gr = node.graphics[ 'links' ][ lnk.id ][ j ];
		    this.set.exclude( gr );
		    gr.hide();		    
		}
		delete lnk.links[ node_id ];
		
		this._unpopulate_line( this.mkey[ lnk.id ][ 0 ], this.mkey[ lnk.id ][ 1 ], this.mkey[ node_id ][ 0 ], this.mkey[ node_id ][ 1 ] );
	    }
	    for( var i=0; i < node.graphics[ 'self' ].length; i++ ) {
		var gr = node.graphics[ 'self' ][ i ];
		this.set.exclude( gr );
		gr.hide();
	    }
	    var x = this.mkey[ node_id ][ 0 ];
	    var y = this.mkey[ node_id ][ 0 ];
	    delete this.matrix[ x ][ y ];
	    delete this.mkey[ node_id ];
	    delete this.nodes[ node_id ];
	    delete this.placed[ node_id ];
	},
	_mark_dist : function( a, b, d ) {
	    if( typeof this.distances[ a ] === 'undefined' ) { this.distances[ a ] = {}; }
	    if( typeof this.distances[ b ] === 'undefined' ) { this.distances[ b ] = {}; }
	    this.distances[ a ][ b ] = d;
	    this.distances[ b ][ a ] = d;
	},
	_stored_dist : function ( a, b ) {
	    if( a in this.distances ) {
		if( b in this.distances[ a ] ) {
		    return this.distances[ a ][ b ];
		}
	    }
	    return -1;
	},
	_dist: function( anode, bnode, seen ) {
	    if( anode == bnode ) return 0;
	    if( ! seen ) {  seen = {}; }

	    seen[ anode ] = 1;

	    var sd = this._stored_dist( anode, bnode );
	    if( sd > -1 ) { return sd; }

	    var linkids = Object.keys( this.nodes[ anode ].links );
	    for( var i=0; i < linkids.length; i++ ) {
		var link = this.nodes[ anode ].links[ linkids[ i ] ];
		if( link.id == bnode ) {
		    this._mark_dist( anode, bnode, 1 );
		    return 1;
		}
	    }
	    var linkids = Object.keys( this.nodes[ bnode ].links );
	    for( var i=0; i < linkids.length; i++ ) {
		var link = this.nodes[ bnode ].links[ linkids[ i ] ];
		if( link.id == anode ) {
		    this._mark_dist( anode, bnode, 1 );
		    return 1;
		}
	    }

	    var mindist = 0;
	    var linkids = Object.keys( this.nodes[ anode ].links );
	    for( var i=0; i < linkids.length; i++ ) {
		var link = this.nodes[ anode ].links[ linkids[ i ] ];
		if( typeof seen[ link.id ] === 'undefined' ) {
		    var new_seen = {}
		    for( var key in seen ) {
			new_seen[ key ] = seen[ key ];
		    }
		    var d = this._dist( link.id, bnode, new_seen );
		    if( d > 0 ) {
			if( mindist == 0 || mindist > d ) {
			    mindist = d;
			}
		    }
		    seen[ link.id ] = 1;
		}
	    }

	    if( mindist == 0 ) {
		return -1;
	    } 
	    this._mark_dist( anode, bnode, 1 + mindist );
	    return 1 + mindist;    
	}, // _dist
	_populate_line : function ( x1, y1, x2, y2 ) {
	    var m = x2 == x1 ? Infinity : ( y2 - y1 ) / ( x2 - x1 );
	    var start, end;
	    var b = y1 - m*x1;
	    if( m >= 1 ) { //is steep, so use the ys
		if( y1 < y2 ) {
		    start = y1;
		    end = y2;
		} else {
		    start = y2;
		    end = y1;
		} // y = mx + b; x = ( y - b ) / m
		for( var j = (1+start); j < end; j++ ) {
		    var newx = m == Infinity ? x1 : Math.round( ( j - b ) / m );
		    if( typeof this.matrix[ newx ] === 'undefined' ) { this.matrix[ newx ] = {}; }
		    if( typeof this.matrix[ newx ][ j ] !== 'object' ) {
			if( typeof this.matrix[ newx ][ j ] === 'undefined' ) {
			    this.matrix[ newx ][ j ] = 0;
			}
			this.matrix[ newx ][ j ]++;
		    }
		}
	    } else {
		if( x1 < x2 ) { 
		    start = x1;
		    end = x2;
		} else {
		    start = x2;
		    end = x1;
		}
		for( var j = ( 1 + start ); j < end; j++ ) {
		    var newy = Math.round( m * j + b );
		    if( typeof this.matrix[ j ] === 'undefined' ) { this.matrix[ j ] = {}; }
		    if( typeof this.matrix[ j ][ newy ] !== 'object' ) {
			if( typeof this.matrix[ j ][ newy ] === 'undefined' ) {
			    this.matrix[ j ][ newy ] = 0;
			}
			this.matrix[ j ][ newy ]++;
		    }
		}
	    }
	}, //_populate_line
	_unpopulate_line : function ( x1, y1, x2, y2 ) {
	    var m = x2 == x1 ? Infinity : ( y2 - y1 ) / ( x2 - x1 );
	    var start, end;
	    var b = y1 - m*x1;
	    if( m >= 1 ) { //is steep, so use the ys
		if( y1 < y2 ) {
		    start = y1;
		    end = y2;
		} else {
		    start = y2;
		    end = y1;
		} // y = mx + b; x = ( y - b ) / m
		for( var j = (1+start); j < end; j++ ) {
		    var newx = m == Infinity ? x1 : Math.round( ( j - b ) / m );
		    if( typeof this.matrix[ newx ] === 'undefined' ) { this.matrix[ newx ] = {}; }
		    if( typeof this.matrix[ newx ][ j ] !== 'object' && typeof this.matrix[ newx ][ j ] === 'undefined' ) {
			this.matrix[ newx ][ j ]--;
			if( this.matrix[ newx ][ j ] == 0 ) {
			    delete this.matrix[ newx ][ j ];
			}
		    }
		}
	    } else {
		if( x1 < x2 ) { 
		    start = x1;
		    end = x2;
		} else {
		    start = x2;
		    end = x1;
		}
		for( var j = ( 1 + start ); j < end; j++ ) {
		    var newy = Math.round( m * j + b );
		    if( typeof this.matrix[ j ] === 'undefined' ) { this.matrix[ j ] = {}; }
		    if( typeof this.matrix[ j ][ newy ] !== 'object' && typeof this.matrix[ j ][ newy ] === 'undefined' ) {
			this.matrix[ j ][ newy ]--;
			if( this.matrix[ j ][ newy ] == 0 ) {
			    delete this.matrix[ j ][ newy ];
			}
		    }
		}
	    }
	}, //_unpopulate_line
	_has_blocked_lines : function( node, x, y ) {
	    var linkids = Object.keys( node.links );
	    for( var i = 0 ; i < linkids.length; i++ ) {
		var linknode = node.links[ linkids[ i ] ];
		if( typeof this.mkey[ linknode.id ] !== 'undefined' ) {
		    // check the line between the node and this linked node
		    // make sure that line doesn't tread on things in the matrix
		    var x1 = x, y1 = y, x2 = this.mkey[ linknode.id ][ 0 ], y2 = this.mkey[ linknode.id ][ 1 ];
		    var m = x2 == x1 ? Infinity : ( y2 - y1 ) / ( x2 - x1 );
		    var start, end;
		    var b = y1 - m*x1;
		    if( m >= 1 ) { //is steep, so use the ys
			if( y1 < y2 ) {
			    start = y1; 
			    end = y2 + 1;
			} else {
			    start = y2 + 1;
			    end = y1;
			} // y = mx + b; x = ( y - b ) / m
			for( var j = start; j < end; j++ ) {
			    var newx = m == Infinity ? x1 : Math.round( ( j - b ) / m );
			    if( typeof this.matrix[ newx ] !== 'undefined' && typeof this.matrix[ newx ][ j ] === 'object' ) {
				return true;
			    }
			}
		    } else {
			if( x1 < x2 ) { 
			    start = x1; // the test placement x ------ > link
			    end = x2 + 1;
			} else {
			    start = x2 + 1;
			    end = x1; // ends up at the test placement link ---> x
			}
			for( var j = start; j < end; j++ ) {
			    var newy = m * j + b;
			    if( typeof this.matrix[ j ] !== 'undefined' && typeof this.matrix[ j ][ newy ] === 'object' ) {
				return true;
			    }
			}
		    }
		} // if the link has been placed
	    } //each link of the node
	    return false;
	}, //_has_blocked_lines
	remove:function( node ) {
	    
	},
	_has_straight_line : function ( unplacednode, x, y ) {
	    //check links
	    var taken_x = {};
	    var taken_y = {};

	    var linkids = Object.keys( unplacednode.links );
	    for( var i = 0 ; i < linkids.length; i++ ) {
		var l = unplacednode.links[ linkids[ i ] ];
		var lpos = this.mkey[ l.id ];
		if( typeof lpos !== 'undefined' ) {
		    if( taken_x[ lpos[ 0 ] ] == 1 || taken_y[ lpos[ 1 ] ] == 1 ) {
			return true;
		    }
		    taken_x[ lpos[ 0 ] ] == 1;
		    taken_y[ lpos[ 1 ] ] == 1;
		}
	    }
	    return false;
	}, //_has_straight_line

	_add_one_to_matrix : function( node ) {
	    var thisgraph = this;
	    
	    var placedids = Object.keys( this.placed );
	    placedids = placedids.sort( function( a, b ) { 
		return thisgraph._dist( node.id, thisgraph.placed[ a ][ 0 ].id, {} ) - 
		    thisgraph._dist( node.id, thisgraph.placed[ b ][ 0 ].id, {} ) } );
	    
	    var nextx, nexty;

	    var linkids = Object.keys( node.links );
	    if( linkids.length == 1 ) {
		nextx = this.placed[ placedids[ 0 ] ][ 1 ];
		nexty = this.placed[ placedids[ 0 ] ][ 2 ] + ( Math.random() > .5 ? -1 : 1 );
	    } else {
		nextx = Math.round( this.placed[ placedids[ 0 ] ][ 1 ] + this.placed[ placedids[ 1 ] ][ 1 ] / 2.0 );	    
		nexty = Math.round( this.placed[ placedids[ 0  ]][ 2 ] + this.placed[ placedids[ 1 ] ][ 2 ] / 2.0 );
	    }

	    if( typeof this.matrix[ nextx ] === 'undefined' ) { this.matrix[ nextx ] = {}; }

	    var useX = false;
	    var firstX = nextx, firstY = nexty;
	    while( typeof this.matrix[ nextx ][ nexty ] !== 'undefined' 
		   || this._has_blocked_lines( node, nextx, nexty )
		   || this._has_straight_line( node, nextx, nexty )
		 ) {
		var val = Math.random() > .5 ? 1 : -1;
		if( useX ) {
		    nextx += val;
		    if( typeof this.matrix[ nextx ] === 'undefined' ) { this.matrix[ nextx ] = {}; }
		} else {
		    nexty += val;
		}
		useX = Math.random() > .5;
		if( Math.abs( firstX - nextx ) > 4 ) {
		    nextx = firstX;
		}
		if( Math.abs( firstY - nexty ) > 4 ) {
		    nexty = firstY;
		}
	    } 
	    this.matrix[ nextx ][ nexty ] = node;
	    this.mkey[ node.id ] = [ nextx, nexty ]

	    //each placed thing, connect the lines
	    var placedids = Object.keys( this.placed );
	    for( var j=0; j < placedids.length; j++ ) {
	    	this._populate_line( nextx, nexty, this.placed[ placedids[ j ] ][ 1 ] , this.placed[ placedids[ j ] ][ 2 ]  );
	    }
	    this.placed[ node.id ] = [ node, nextx, nexty ];
	}, //_add_one_to_matrix

	build_matrix : function() {
	    this.matrix = { 0 : {} };
	    this.placed = {};
	    var thisgraph = this;

	    var ids = Object.keys( this.nodes );
	    var thisgraph = this;
	    ids.sort( function( a, b ) { return Object.keys( thisgraph.nodes[ b ].links ).length - Object.keys( thisgraph.nodes[ a ].links ).length; } );
	    // first

	    this.matrix[ 0 ][ 0 ] = this.nodes[ ids[ 0 ] ];
	    this.placed[ ids[ 0 ] ] = [ this.nodes[ ids[ 0 ] ], 0, 0 ];
	    this.mkey[ this.nodes[ ids[ 0 ] ].id ] = [ 0, 0 ];

	    // second
	    var x = this._dist( this.nodes[ ids[ 0 ]].id, this.nodes[ ids[ 1 ] ].id, {} );
	    var y = this._dist( this.nodes[ ids[ 0 ]].id, this.nodes[ ids[ 1 ] ].id, {} );
	    this.matrix[ x ] = {};
	    this.matrix[ x ][ y ] = this.nodes[ ids[ 1 ] ];

	    this._populate_line( 0, 0, x, y );

	    this.mkey[ this.nodes[ ids[ 1 ] ].id ] = [ x, y ];
	    this.placed[ ids[ 1 ] ] = [ this.nodes[ ids[ 1 ] ], x, y ];

	    for( var i = 2; i < ids.length; i++ ) {
		// find who this is closest to
		this._add_one_to_matrix( this.nodes[ ids[ i ] ] )
		
	    } //each i
	}, //build_matrix

	cell_size    : 50,
	half_cell    : 25,
	quarter_cell : 5,
	paper        : undefined,
	set          : undefined,

	draw : function() {
	    if( this.paper == undefined ) {
		this.paper = Raphael( 150, 150, 800, 800 );
		this.set = this.paper.set();
	    }
	    for( var key in this.matrix ) {
		for( var okey in this.matrix[ key ] ) {
		    var node = this.matrix[ key ][ okey ];
		    if( typeof node === 'object' && ! node.drawn ) {
			var npos = this.mkey[ node.id ];
			if( typeof this.matrix[ key ][ okey ][ 'offsetx' ] === 'undefined' ) {
			    this.matrix[ key ][ okey ].offsetx = Math.round( this.quarter_cell * ( Math.random() - .5 ) );
			    this.matrix[ key ][ okey ].offsety = Math.round( this.quarter_cell * ( Math.random() - .5 ) );
			}

			var linkids = Object.keys( node.links );
			for( var j=0; j < linkids.length; j++ ) {
			    var link = this.matrix[ key ][ okey ].links[ linkids[ j ] ];
			    var opos = this.mkey[ link.id ];
			    //randomize the center a little bit
			    if( typeof link[ 'offsetx' ] === 'undefined' ) {
				link.offsetx = Math.round( this.quarter_cell * ( Math.random() - .5 ) );
				link.offsety = Math.round( this.quarter_cell * ( Math.random() - .5 ) );
			    }
			    var pth = this.paper.path( "M" + (  link.offsetx + this.half_cell + this.cell_size * opos[ 0 ] ) + ' ' + 
						  ( link.offsety + this.half_cell + this.cell_size * opos[ 1 ] ) + 
						  'L' + ( this.matrix[ key ][ okey ].offsetx + this.half_cell + this.cell_size * npos[ 0 ] ) + ' ' + ( this.matrix[ key ][ okey ].offsety + this.half_cell + this.cell_size * npos[ 1 ] ) );
			    pth.attr( { 'stroke-width' : 2, 
					'opacity' : .4, 
					//				    stroke : clr
				      } );
			    var g = pth.glow();
			    node.graphics[ 'links' ][ link.id ] = [];
			    node.graphics[ 'links' ][ link.id ].push( g );
			    node.graphics[ 'links' ][ link.id ].push( pth );
			    var clr = '#' + Math.round( 5 + 10 * (Math.random() - .5 ) ) + '' + Math.round( 5 + 10 * (Math.random() - .5 ) ) + '' + Math.round( 5 + 10 * (Math.random() - .5 ) );
			    g.attr( { stroke : clr,
				      //				  'opacity' : .2
				    } );
			    this.set.push( pth );
			    this.set.push( g );
			}
		    }
		}
	    } // each item in the matrix
	    var minX = false, minY = false;
	    for( var key in this.matrix ) {
		for( var okey in this.matrix[ key ] ) {
		    var node = this.matrix[ key ][ okey ];
		    if( typeof node === 'object' ) {
			if( minX == false || minX > key * 1 ) {
			    minX = key * 1;
			}
			if( minY == false || minY > okey * 1 ) {
			    minY = okey * 1;
			}
			if( ! node.drawn ) {
			    if( typeof node === 'object' ) {
				var c = this.paper.circle( this.matrix[ key ][ okey ].offsetx + key * this.cell_size + this.half_cell, 
							   this.matrix[ key ][ okey ].offsety + this.cell_size * okey + this.half_cell, 
							   10 );
				c.attr( { fill : '20-#3B4-#BFB' } );
				var g = c.glow();
				node.graphics[ 'self' ].push( g );
				node.graphics[ 'self' ].push( c );

				this.set.push( g );
				this.set.push( c );
				var txt = this.paper.text( this.matrix[ key ][ okey ].offsetx + key * this.cell_size + this.half_cell, 
							   this.matrix[ key ][ okey ].offsety + this.cell_size * okey + this.half_cell, 
							   this.matrix[ key ][ okey ].name );
				console.log( "Adding text " + this.matrix[ key ][ okey ].name );
				this.set.push( txt );
				node.graphics[ 'self' ].push( txt );
			    }
			    node.drawn = true;
			}
		    } //if not drawn
		}
	    }
	    
	    var tX = this.cell_size, tY = this.cell_size;
	    if( minX < 0 ) { tX -= this.cell_size * minX; }
	    if( minY < 0 ) { tY -= this.cell_size * minY; }
	    
	    this.set.forEach( function( el ) { el.transform( "t" + tX + ',' + tY ); } );
//	    this.set.animate( { transform : "t" + tX + ',' + tY }, 1000 );
	} //draw
	
    };
} //graph
