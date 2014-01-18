package StellarExpanse::Flavor;

use strict;

use StellarExpanse::Ship;

use base 'Yote::RootObj';

our @defaultships=(
    {
	name => 'Scout',
	ship_class => 'Scout',
	tech_level => 1,
	damage_control => '0',
	jumps => '5',
	design_id => '1',
	cost => '3',
	targets => '0',
	self_destruct => '0',
	attack_beams => '0',
	defense => '1',
	size => '4',
	racksize => '0',
	type => 'SHIP'
    },
    {
	name => 'Patrol_Boat',
	ship_class => 'Patrol_Boat',
	tech_level => '1',
	damage_control => '0',
	jumps => '4',
	design_id => '2',
	cost => '8',
	targets => '1',
	self_destruct => '0',
	attack_beams => '6',
	defense => '7',
	size => '8',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Destroyer',
	ship_class => 'Destroyer',
	tech_level => '1',
	damage_control => '2',
	jumps => '3',
	design_id => '3',
	cost => '20',
	targets => '3',
	self_destruct => '0',
	attack_beams => '15',
	defense => '19',
	size => '20',
	racksize => '0',
	type => 'SHIP'
    },
    
    {
	name => 'Cruiser',
	ship_class => 'Cruiser',
	tech_level => '1',
	damage_control => '3',
	jumps => '2',
	design_id => '4',
	cost => '30',
	targets => '3',
	self_destruct => '0',
	attack_beams => '30',
	defense => '25',
	size => '30',
	racksize => '0',
	type => 'SHIP'
    },
    
    {
	name => 'Battleship',
	ship_class => 'Battleship',
	tech_level => '1',
	damage_control => '6',
	jumps => '1',
	design_id => '5',
	cost => '45',
	targets => '6',
	self_destruct => '0',
	attack_beams => '44',
	defense => '46',
	size => '50',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Carrier',
	ship_class => 'Carrier',
	tech_level => '1',
	damage_control => '2',
	jumps => '1',
	design_id => '6',
	cost => '20',
	targets => '2',
	self_destruct => '0',
	attack_beams => '10',
	defense => '15',
	size => '45',
	racksize => '6',
	type => 'SHIP'
    },
    
    {
	name => 'Fighter_Wing',
	ship_class => 'Fighter_Wing',
	tech_level => '1',
	damage_control => '0',
	jumps => '0',
	design_id => '7',
	cost => '6',
	targets => '1',
	self_destruct => '0',
	attack_beams => '6',
	defense => '5',
	size => '3',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Orbital_Weapon_Platform',
	ship_class => 'Orbital_Weapon_Platform',
	tech_level => '1',
	damage_control => '4',
	jumps => '0',
	design_id => '8',
	cost => '20',
	targets => '4',
	self_destruct => '0',
	attack_beams => '30',
	defense => '36',
	size => '12',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Planetary_Industry',
	ship_class => 'Planetary_Industry',
	tech_level => '1',
	damage_control => '-',
	jumps => '-',
	design_id => '9',
	cost => '5',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'IND'
    },

    {
	name => 'Tech_Level_2',
	ship_class => 'Tech_Level_2',
	tech_level => '1',
	provides_tech => '2',
	damage_control => '-',
	jumps => '-',
	design_id => '10',
	cost => '100',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'TECH'
    },

    {
	name => 'Gunship',
	ship_class => 'Gunship',
	tech_level => '2',
	damage_control => '1',
	jumps => '4',
	design_id => '11',
	cost => '6',
	targets => '1',
	self_destruct => '0',
	attack_beams => '6',
	defense => '8',
	size => '8',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Frigate',
	ship_class => 'Frigate',
	tech_level => '2',
	damage_control => '1',
	jumps => '3',
	design_id => '12',
	cost => '20',
	targets => '2',
	self_destruct => '0',
	attack_beams => '25',
	defense => '13',
	size => '18',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Heavy_Cruiser',
	ship_class => 'Heavy_Cruiser',
	tech_level => '2',
	damage_control => '5',
	jumps => '2',
	design_id => '13',
	cost => '37',
	targets => '3',
	self_destruct => '0',
	attack_beams => '35',
	defense => '46',
	size => '40',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Light_Carrier',
	ship_class => 'Light_Carrier',
	tech_level => '2',
	damage_control => '0',
	jumps => '2',
	design_id => '14',
	cost => '10',
	targets => '0',
	self_destruct => '0',
	attack_beams => '0',
	defense => '9',
	size => '25',
	racksize => '4',
	type => 'SHIP'
    },

    {
	name => 'Attack_Wing',
	ship_class => 'Attack_Wing',
	tech_level => '2',
	damage_control => '0',
	jumps => '0',
	design_id => '15',
	cost => '6',
	targets => '1',
	self_destruct => '0',
	attack_beams => '7',
	defense => '6',
	size => '3',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Missile',
	ship_class => 'Missile',
	tech_level => '2',
	damage_control => '0',
	jumps => '0',
	design_id => '16',
	cost => '3',
	targets => '1',
	self_destruct => '1',
	attack_beams => '12',
	defense => '1',
	size => '2',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Orbital_Fortress',
	ship_class => 'Orbital_Fortress',
	tech_level => '2',
	damage_control => '10',
	jumps => '0',
	design_id => '17',
	cost => '40',
	targets => '8',
	self_destruct => '0',
	attack_beams => '60',
	defense => '81',
	size => '20',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Tech_Level_3',
	ship_class => 'Tech_Level_3',
	provides_tech => '3',
	tech_level => '2',
	damage_control => '-',
	jumps => '-',
	design_id => '18',
	cost => '200',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'TECH'
    },

    {
	name => 'Light_Cruiser',
	ship_class => 'Light_Cruiser',
	tech_level => '3',
	damage_control => '2',
	jumps => '2',
	design_id => '19',
	cost => '20',
	targets => '3',
	self_destruct => '0',
	attack_beams => '26',
	defense => '21',
	size => '25',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Dreadnaught',
	ship_class => 'Dreadnaught',
	tech_level => '3',
	damage_control => '8',
	jumps => '1',
	design_id => '20',
	cost => '60',
	targets => '10',
	self_destruct => '0',
	attack_beams => '80',
	defense => '61',
	size => '65',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Heavy_Carrier',
	ship_class => 'Heavy_Carrier',
	tech_level => '3',
	damage_control => '4',
	jumps => '1',
	design_id => '21',
	cost => '30',
	targets => '2',
	self_destruct => '0',
	attack_beams => '10',
	defense => '31',
	size => '55',
	racksize => '9',
	type => 'SHIP'
    },

    {
	name => 'Interceptor_Wing',
	ship_class => 'Interceptor_Wing',
	tech_level => '3',
	damage_control => '0',
	jumps => '0',
	design_id => '22',
	cost => '4',
	targets => '1',
	self_destruct => '0',
	attack_beams => '5',
	defense => '5',
	size => '2',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Minesweeper',
	ship_class => 'Minesweeper',
	tech_level => '3',
	damage_control => '0',
	jumps => '1',
	design_id => '23',
	cost => '10',
	targets => '5',
	self_destruct => '0',
	attack_beams => '5',
	defense => '13',
	size => '20',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Starbase',
	ship_class => 'Starbase',
	tech_level => '3',
	damage_control => '30',
	jumps => '0',
	design_id => '24',
	cost => '60',
	targets => '10',
	self_destruct => '0',
	attack_beams => '125',
	defense => '121',
	size => '100',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Orbital_Industry',
	ship_class => 'Orbital_Industry',
	tech_level => '3',
	damage_control => '-',
	jumps => '-',
	design_id => '25',
	cost => '10',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'OIND'
    },

    {
	name => 'Tech_Level_4',
	ship_class => 'Tech_Level_4',
	provides_tech => '4',
	tech_level => '3',
	damage_control => '-',
	jumps => '-',
	design_id => '26',
	cost => '300',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'TECH'
    },

    {
	name => 'Battlecruiser',
	ship_class => 'Battlecruiser',
	tech_level => '4',
	damage_control => '3',
	jumps => '4',
	racksize => '0',

	design_id => '27',
	cost => '40',
	targets => '4',
	self_destruct => '0',
	attack_beams => '45',
	defense => '36',
	size => '40',
	type => 'SHIP'
    },
    {
	name => 'SuperDreadnaught',
	ship_class => 'SuperDreadnaught',
	tech_level => '4',
	damage_control => '8',
	jumps => '1',
	design_id => '28',
	cost => '80',
	targets => '10',
	self_destruct => '0',
	attack_beams => '100',
	defense => '89',
	size => '70',
	racksize => '0',
	type => 'SHIP'
    },
    {
	name => 'Fleet_Carrier',
	ship_class => 'Fleet_Carrier',
	tech_level => '4',
	damage_control => '8',
	jumps => '1',
	design_id => '29',
	cost => '40',
	targets => '2',
	self_destruct => '0',
	attack_beams => '10',
	defense => '51',
	size => '65',
	racksize => '12',
	type => 'SHIP'
    },

    {	
	name => 'Strike_Wing',
	ship_class => 'Strike_Wing',
	tech_level => '4',
	damage_control => '0',
	jumps => '0',
	design_id => '30',
	cost => '10',
	targets => '1',
	self_destruct => '0',
	attack_beams => '11',
	defense => '6',
	size => '3',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Heavy_Missile',
	ship_class => 'Heavy_Missile',
	tech_level => '4',
	damage_control => '0',
	jumps => '0',
	design_id => '31',
	cost => '10',
	targets => '1',
	self_destruct => '1',
	attack_beams => '31',
	defense => '1',
	size => '3',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Tech_Level_5',
	ship_class => 'Tech_Level_5',
	tech_level => '4',
	damage_control => '-',
	jumps => '-',
	design_id => '32',
	cost => '400',
	targets => '-',
	self_destruct => '0',
	attack_beams => '-',
	defense => '-',
	size => '-',
	racksize => '-',
	type => 'TECH'
    },

    {
	name => 'Monitor',
	ship_class => 'Monitor',
	tech_level => '5',
	damage_control => '25',
	jumps => '1',
	design_id => '33',
	cost => '90',
	targets => '10',
	self_destruct => '0',
	attack_beams => '80',
	defense => '145',
	size => '100',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Capitol_Missile',
	ship_class => 'Capitol_Missile',
	tech_level => '5',
	damage_control => '0',
	jumps => '0',
	design_id => '34',
	cost => '20',
	targets => '1',
	self_destruct => '1',
	attack_beams => '61',
	defense => '1',
	size => '4',
	racksize => '0',
	type => 'SHIP'
    },

    {
	name => 'Jump_Missile',
	ship_class => 'Jump_Missile',
	tech_level => '5',
	damage_control => '0',
	jumps => '1',
	design_id => '35',
	cost => '10',
	targets => '1',
	self_destruct => '1',
	attack_beams => '20',
	defense => '1',
	size => '6',
	racksize => '0',
	type => 'SHIP'
    },

    ); #defaultships

our $univ_sector_config = q~
<groups>
 <group ring>
  exclusion_flags 0
  <sector A>
   outbound_links 1
  </sector A>
  <sector B>
   outbound_links 1
  </sector>
  <sector C>
   outbound_links 1
  </sector>
  <sector D>
   outbound_links 1
  </sector>
  <sector E>
   outbound_links 1
  </sector>
  <sector F>
   outbound_links 1
  </sector>
  internal_link A B
  internal_link B C
  internal_link C D
  internal_link D E
  internal_link E F
  internal_link F A
 </group>
 <group dia1>
  exclusion_flags 0
  <sector A>
  </sector A>
  <sector B>
   outbound_links 1
  </sector>
  <sector C>
   outbound_links 1
  </sector>
  <sector D>
   outbound_links 1
  </sector>
  internal_link A B
  internal_link A C
  internal_link A D
  internal_link B C
  internal_link B D
  internal_link C D
 </group>
 <group line2>
  exclusion_flags 0
  <sector A>
   outbound_links 2
  </sector A>
  <sector B>
  </sector>
  <sector C>
   outbound_links 2
  </sector>
  internal_link A B
  internal_link B C
 </group>
 <group tri1>
  exclusion_flags 0
  <sector A>
   outbound_links 1
  </sector A>
  <sector B>
   outbound_links 1
  </sector>
  <sector C>
   outbound_links 1
  </sector>
  internal_link A B
  internal_link A C
  internal_link B C
 </group>
 <group tri2>
  exclusion_flags 0
  <sector A>
   outbound_links 2
  </sector A>
  <sector B>
   outbound_links 2
  </sector>
  <sector C>
   outbound_links 2
  </sector>
  internal_link A B
  internal_link A C
  internal_link B C
 </group>
 <group mouse2>
  exclusion_flags 0
  <sector A>
   outbound_links 2
  </sector A>
  <sector B>
  </sector>
  <sector C>
  </sector>
  internal_link A B
  internal_link A C
 </group>
 <group end2>
  exclusion_flags 0
  <sector A>
   outbound_links 2
  </sector A>
  <sector B>
  </sector>
  internal_link A B
 </group>
</groups>
    ~;

our $empire_sector_config = q~
<empires>
 <group dia1>
  prod_type empire
  exclusion_flags 1
  <sector A>
   currprod 20
   maxprod 25
  </sector>
  <sector B>
   outbound_links 1
   owner -1
  </sector>
  <sector C>
   outbound_links 1
   owner -1
  </sector>
  <sector D>
   outbound_links 1
   owner -1
  </sector>
  internal_link A B
  internal_link A C
  internal_link A D
  internal_link B C
  internal_link C D
 </group>
</empires>
~;

our $game_sector_config = q~
<player>
 resources 0
 tl 1
</player>

target_sector_count 90

<prod_type_group empire>
 <prod_type empire>
  SectorMaxProdRange 8 15
  SectorProdRange 0
 </prod_type>
</prod_type_group>
<prod_type_group default>
 <prod_type low>
  SectorMaxProdRange 0 7
  SectorProdRange 0
  Weight 8
 </prod_type>
 <prod_type mid>
  SectorMaxProdRange 5 10
  SectorProdRange 0
  Weight 4
 </prod_type>
 <prod_type high>
  SectorMaxProdRange 9 15
  SectorProdRange 0
  Weight 2
 </prod_type>
 <prod_type vhigh>
  SectorMaxProdRange 12 20
  SectorProdRange 0
  Weight 1
 </prod_type>
</prod_type_group>
~;
our $base_sector_config = q~
<basegroups>
 <group ring>
  exclusion_flags 0
  <sector A>
   outbound_links 1
  </sector A>
  <sector B>
   outbound_links 1
  </sector>
  <sector C>
   outbound_links 1
  </sector>
  <sector D>
   outbound_links 1
  </sector>
  <sector E>
   outbound_links 1
  </sector>
  <sector F>
   outbound_links 1
  </sector>
  internal_link A B
  internal_link B C
  internal_link C D
  internal_link D E
  internal_link E F
  internal_link F A
 </group>
</basegroups>
~;
sub _init {
    my $self = shift;
    $self->SUPER::_init();
    for my $def (@defaultships) {
        my $prototype = new StellarExpanse::Ship( $def );
        $self->add_to_ships( $prototype );
    }
    $self->set_empire_config( $empire_sector_config );
    $self->set_base_config( $base_sector_config );
    $self->set_game_config( $game_sector_config );
    $self->set_universe_config( $univ_sector_config );
    $self->set_sector_names('');
} #init

sub precache {
    my( $self, $data, $acct ) = @_;
    return [ map { $_, $_->precache() } @{ $self->get_ships() } ];
} #precache

1;

__END__

Flavor data fields :
    ships - []

   the rest are text

    empire_config
    base_config
    game_config
    universe_config  

    sector_names      - a string of newline delimited sector names to use
