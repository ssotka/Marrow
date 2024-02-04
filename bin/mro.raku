#!/usr/bin/env raku

#use lib "lib";
use DB::Pg;
use JSON::Pretty;
use API::Db;
use API::Db::Conv;
use API::Db::App;
use API::Db::Mods;
use API::Db::Roles;
use API::Db::Templates;
use API::Db::Dockerfile;


sub MAIN(   Bool :$app=False, #= Generate the Cro app that implements the REST APIs.
            Bool :$mods=False, #= Generate empty Class modules that can be modified by users (one to implement each role).
            Bool :$roles=False, #= Generate roles implemented by the modules (one for each table in the schema).
            Bool :$templates=False, #= Generate HTML template interface.
            Bool :$list=False, #= List the DB schemas (postgreSQL only)
            Str :$db-type, #= The type of database (sqlite, pg, mysql, etc).
            Str :$dbname=%*ENV<DB_NAME>, #= The name of the database - env DB_NAME (filename for SQLite).
            Str :$host=%*ENV<DB_HOST>, #= The host name of the database - env DB_HOST.
            Str :$port=$*ENV<DB_PORT>, #= The port number of the database - env DB_PORT.
            Str :$user=%*ENV<DB_USER>, #= The user name for the database - env DB_USER.
            Str :$password=%*ENV<DB_PASS>, #= The password for the database - env DB_PASS.
            Str :$schema='public', #= The name of the schema to use.
            Str :$prefix = 'public', #= The library prefix to use for the generated code.
            Str :$app-host=$*ENV<APP_HOST>, #= The host name for the app - env APP_HOST. 
            Str :$app-port=$*ENV<APP_PORT>, #= The port number for the app - env APP_PORT.
            Bool :$help=False #= Displays this message.
            ) {

    my $db = API::Db.new(db-type => $db-type, dbname => $dbname, host => $host, port => $port, 
                        user => $user, password => $password);
    say $db.query-hash.keys;
    my $db-type-conv = API::Db::Conv.new(db => $db-type);

    $db.list-schemas-and-exit       if $list;
    $db.check-schema-name($schema)  if $schema ne 'public';

    our $db-base-name;
    if $db-type eq 'sqlite' {
        my $f = $dbname.IO;
        $db-base-name = ($f.IO.extension("")).IO.basename;
    }

    say "db-base-name: $db-base-name";

    our %tables = $db.get-tables( $schema );
    say to-json %tables;
    unless defined($prefix) { $prefix = $schema.tc }
    
    make_db_conn( $prefix );
    make_app($db-base-name, $db-type-conv, $schema, $prefix, %tables) if $app;
    make_mods($schema, $prefix, %tables) if $mods;

    my $meta-conn = q/my $conninfo = join " ",
        ('dbname=' ~ (%*ENV<DB_NAME> || die("missing DB_NAME in environment"))),
        ("host=$_" with %*ENV<DB_HOST>),
        ("port=$_" with %*ENV<DB_PORT>),
        ("user=$_" with %*ENV<DB_USER>),
        ("password=$_" with %*ENV<DB_PASS>);/;

    make_roles($schema, $db-type-conv, $prefix, $db-type, $meta-conn, %tables) if $roles;
    make_templates( $schema, $prefix, $db-type, $app-host, $app-port, %tables ) if $templates;
    make_dockerfile( $db-base-name, $app-port ) if $app;
    make_envfile( $dbname, $db-type, $host, $port, $user, $password, $app-host, $app-port ) if $app;
}
