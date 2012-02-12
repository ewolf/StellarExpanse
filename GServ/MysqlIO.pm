package GServ::MysqlIO;

#
# This stows and fetches G objects from a database store and provides object ids.
#

use strict;
use feature ':5.10';

use Data::Dumper;
use DBI;

use constant {
    DATA => 2,
    MAX_LENGTH => 1025,
};

sub new {
    my $pkg = shift;
    my $class = ref( $pkg ) || $pkg;
    my $args = ref( $_[0] ) ? $_[0] : { @_ };

    my $self = {
        args => $args,
    };
    bless $self, $class;
    $self->connect( $args );
    return $self;
} #new

sub connect {
    my $self  = shift;
    my $args  = ref( $_[0] ) ? $_[0] : { @_ };
    my $db    = $args->{database} || $self->{args}{database} || 'sg';
    my $uname = $args->{uname} || $self->{args}{uname};
    my $pword = $args->{pword} || $self->{args}{pword};
    $self->database( "DBI:mysql:$db", $uname, $pword );
} #connect

sub reconnect {
    my $self = shift;
    $self->connect();
}

sub init_datastore {
    my $self = shift;
    my $args = ref( $_[0] ) ? $_[0] : { @_ };
    my $db = $args->{db}       || $self->{args}{db};
    my $uname = $args->{uname} || $self->{args}{uname};
    my $pword = $args->{pword} || $self->{args}{pword};

    $self->database( "DBI:mysql:$db", $uname, $pword );

    my %definitions = (
        field => q~CREATE TABLE `field` (
                   `obj_id` int(10) unsigned NOT NULL,
                   `field` varchar(300) DEFAULT NULL,
                   `ref_id` int(10) unsigned DEFAULT NULL,
                   `value` varchar(1025) DEFAULT NULL,
                   KEY `obj_id` (`obj_id`),
                   KEY `ref_id` (`ref_id`)
               ) ENGINE=InnoDB DEFAULT CHARSET=latin1~,
        big_text => q~CREATE TABLE `big_text` (
                       `obj_id` int(10) unsigned NOT NULL,
                       `text` text,
                       PRIMARY KEY (`obj_id`)
                      ) ENGINE=InnoDB CHARSET=latin1~,
        objects => q~CREATE TABLE `objects` (
                     `id` int(11) NOT NULL AUTO_INCREMENT,
                     `class` varchar(255) DEFAULT NULL,
                      PRIMARY KEY (`id`)
                      ) ENGINE=InnoDB DEFAULT CHARSET=latin1~
        );
    $self->{DBH}->do( "START TRANSACTION" );
    my $today = $self->{DBH}->selectrow_array( "SELECT now()" );
    $today =~ s/[^0-9]+//g;
    for my $table (keys %definitions ) {
        my( $t ) = $self->{DBH}->selectrow_array( "SHOW TABLES LIKE '$table'" );
        if( $t ) {
            my $existing_def = $self->{DBH}->selectall_arrayref( "SHOW CREATE TABLE $table" );
            my $current_def = $definitions{$table};

            #normalize whitespace for comparison
            $current_def =~ s/[\s\n\r]+/ /gs;
            $existing_def =~ s/[\s\n\r]+/ /gs;

            if( lc( $current_def ) eq lc( $existing_def ) ) {
                print STDERR "Table '$table' exists and is the same version\n";
            } else {
                my $backup = "${table}_$today";
                print STDERR "Table definition mismatch for $table. Rename old table '$table' to '$backup' and creating new one.\n";
                $self->{DBH}->do("RENAME TABLE $table TO $backup\n");
                $self->{DBH}->do( $definitions{$table} );
            }
        } else {
            print STDERR "Creating table $table\n";
            $self->{DBH}->do( $definitions{$table} );
        }
    }
    $self->{DBH}->selectrow_array( "COMMIT" );
} #init_datastore

sub database {
    my $self = shift;
    if( @_ ) {
        $self->{DBH} = DBI->connect( @_ );
    }
    return $self->{DBH};
}

#
# Returns the number of entries in the data structure given.
#
sub xpath_count {
    my( $self, $path ) = @_;
    my( @list ) = split( /\//, $path );
    my $next_ref = 1;
    for my $l (@list) {
        next unless $l; #skip blank paths like /foo//bar/  (should just look up foo -> bar
        my( $ref ) = $self->{DBH}->selectrow_array( "SELECT ref_id FROM field WHERE field=? AND obj_id=?", {}, $l, $next_ref );
        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

        $next_ref = $ref;
        last unless $next_ref;
    } #each path part

    my( $count ) = $self->{DBH}->selectrow_array( "SELECT count(*) FROM field WHERE obj_id=?", {}, $next_ref );
    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();


    return $count;

} #xpath_count

#
# Returns a single value given the xpath (hash only, and notation is slash separated from root)
# This will always query persistance directly for the value, bypassing objects.
# The use for this is to fetch specific things from potentially very long hashes that you don't want to
#   load in their entirety.
#
sub xpath {
    my( $self, $path ) = @_;
    my( @list ) = split( /\//, $path );
    my $next_ref = 1;
    my $final_val;
    for my $l (@list) {
        next unless $l; #skip blank paths like /foo//bar/  (should just look up foo -> bar
        undef $final_val;
        my( $val, $ref ) = $self->{DBH}->selectrow_array( "SELECT value, ref_id FROM field WHERE field=? AND obj_id=?", {}, $l, $next_ref );
        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

        if( $ref && $val ) {
            my ( $big_val ) = $self->{DBH}->selectrow_array( "SELECT text FROM big_text WHERE obj_id=?", {}, $ref );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            $final_val = "v$big_val";
            last;
        } elsif( $ref ) {
            $next_ref = $ref;
            $final_val = $ref;
        } else {
            $final_val = "v$val";
            last;
        }
    } #each path part

    # @TODO: log bad xpath if final_value not defined

    return $final_val;
} #xpath

#
# Returns a list of objects as a result : All objects connected to the one specified
# by the id.
#
# The objects are returned as array refs with 3 fields :
#   id, class, data
#
sub fetch_deep {
    my( $self, $id, $seen ) = @_;

    $seen ||= {};

    my( $class ) = $self->{DBH}->selectrow_array( "SELECT class FROM objects WHERE id=?", {}, $id );
    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();


    return undef unless $class;
    my $obj = [$id,$class];
    given( $class ) {
        when('ARRAY') {
            $obj->[DATA] = [];
        }
        default {
            $obj->[DATA] = {};
        }
    }

    $seen->{$id} = $obj;

    given( $class ) {
        when('ARRAY') {
            my $res = $self->{DBH}->selectall_arrayref( "SELECT field, ref_id, value FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            for my $row (@$res) {
                my( $idx, $ref_id, $value ) = @$row;
                $obj->[DATA][$idx] = $ref_id || $value;
                if( $ref_id ) {
                    fetch_deep( $ref_id, $seen );
                }
            }
        }
        when('BIGTEXT') {
            ($obj->[DATA]) = $self->{DBH}->selectrow_array( "SELECT text FROM big_text WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

        }
        default {
            my $res = $self->{DBH}->selectall_arrayref( "SELECT field, ref_id, value FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            for my $row (@$res) {
                my( $field, $ref_id, $value ) = @$row;
                $obj->[DATA]{$field} = $ref_id || $value;
                if( $ref_id ) {
                    fetch_deep( $ref_id, $seen );
                }
            }
        } # hash or object
    }

    return [values %$seen];
} #fetch_deep

#
# Returns a single object specified by the id. The object is returned as a hash ref with id,class,data.
#
sub fetch {
    my( $self, $id ) = @_;

    my( $class ) = $self->{DBH}->selectrow_array( "SELECT class FROM objects WHERE id=?", {}, $id );
    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

    return undef unless $class;
    my $obj = [$id,$class];
    given( $class ) {
        when('ARRAY') {
            $obj->[DATA] = [];
            my $res = $self->{DBH}->selectall_arrayref( "SELECT field, ref_id, value FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            for my $row (@$res) {
                my( $idx, $ref_id, $value ) = @$row;
                if( $ref_id && $value ) {
                    my( $val ) = $self->{DBH}->selectrow_array( "SELECT text FROM big_text WHERE obj_id=?", {}, $ref_id );
                    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    ( $obj->[DATA][$idx] ) = "v$val";
                } else {
                    $obj->[DATA][$idx] = $ref_id || "v$value";
                }
            }
        }
        default {
            $obj->[DATA] = {};
            my $res = $self->{DBH}->selectall_arrayref( "SELECT field, ref_id, value FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            for my $row (@$res) {
                my( $field, $ref_id, $value ) = @$row;
                if( $ref_id && $value ) {
                    my( $val ) = $self->{DBH}->selectrow_array( "SELECT text FROM big_text WHERE obj_id=?", {}, $ref_id );
                    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    ( $obj->[DATA]{$field} ) = "v$val";
                } else {
                    $obj->[DATA]{$field} = $ref_id || "v$value";
                }
            }
        }
    }
    return $obj;
} #fetch

#
# Given a class, makes new entry in the objects table and returns the generated id
#
sub get_id {
    my( $self, $class ) = @_;

    my $res = $self->{DBH}->do( "INSERT INTO objects (class) VALUES (?)", {}, $class );
    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

    return $self->{DBH}->last_insert_id(undef,undef,undef,undef);
} #get_id

#
# Stores the object to persistance. Object is an array ref in the form id,class,data
#
sub stow {
    my( $self, $id, $class, $data ) = @_;

    given( $class ) {
        when('ARRAY') {
            $self->{DBH}->do( "DELETE FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

            for my $i (0..$#$data) {
                my $val = $data->[$i];
                if( index( $val, 'v' ) == 0 ) {
                    if( length( $val ) > MAX_LENGTH ) {
                        my $big_id = $self->get_id( "BIGTEXT" );
                        $self->{DBH}->do( "INSERT INTO field (obj_id,field,ref_id,value) VALUES (?,?,?,'V')", {}, $id, $i, $big_id );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                        $self->{DBH}->do( "INSERT INTO big_text (obj_id,text) VALUES (?,?)", {}, $big_id, substr($val,1) );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    } else {
                        $self->{DBH}->do( "INSERT INTO field (obj_id,field,value) VALUES (?,?,?)", {}, $id, $i, substr($val,1) );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    }
                } else {
                    $self->{DBH}->do( "INSERT INTO field (obj_id,field,ref_id) VALUES (?,?,?)", {}, $id, $i, $val );
                    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                }
            }
        }
        default {
            $self->{DBH}->do( "DELETE FROM field WHERE obj_id=?", {}, $id );
            print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();
            for my $key (keys %$data) {
                next if $key eq '__ID__';
                my $val = $data->{$key};
                if( index( $val, 'v' ) == 0 ) {
                    if( length( $val ) > MAX_LENGTH ) {
                        my $big_id = $self->get_id( "BIGTEXT" );
                        $self->{DBH}->do( "INSERT INTO field (obj_id,field,ref_id,value) VALUES (?,?,?,'V')", {}, $id, $key, $big_id );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                        $self->{DBH}->do( "INSERT INTO big_text (obj_id,text) VALUES (?,?)", {}, $big_id, substr($val,1) );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    } else {
                        $self->{DBH}->do( "INSERT INTO field (obj_id,field,value) VALUES (?,?,?)", {}, $id, $key, substr($val,1) );
                        print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                    }
                }
                else {
                    $self->{DBH}->do( "INSERT INTO field (obj_id,field,ref_id) VALUES (?,?,?)", {}, $id, $key, $val );
                    print STDERR Data::Dumper->Dump(["db __LINE__",$self->{DBH}->errstr()]) if $self->{DBH}->errstr();

                }
            } #each key
        }
    }
} #stow


1;
__END__

=head1 AUTHOR

Eric Wolf

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 Eric Wolf

This module is free software; it can be used under the same terms as perl
itself.

=cut
