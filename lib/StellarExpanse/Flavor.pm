package StellarExpanse::Flavor;

use strict;

use base 'Yote::Obj';

our @defaultships=(
    {
	name => 'Scout',
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
	tech_level => '1',
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

sub init {
    my $self = shift;

    for my $def (@defaultships) {
        my $prototype = new Yote::Obj;
        $prototype->absorb( $def );
        $self->add_to_ships( $prototype );
    }
    $self->set_sector_names( [] );
} #init

1;

__END__
