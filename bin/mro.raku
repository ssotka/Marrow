#!/usr/bin/env raku

#use lib "lib";
use DB::Pg;
use JSON::Pretty;
use Getopt::Long;
use API::Db;
use API::Db::Conv;
use API::Db::App;
use API::Db::Mods;
use API::Db::Roles;
use API::Db::Templates;
use API::Db::Dockerfile;


# get-options (
#     "app" => our $app,
#     "mods" => our $mods,
#     "roles" => our $roles,
#     "templates" => our $templates,
#     "schema=s" => our $schema
# );

our $pg;


            
sub usage {
    say $*PROGRAM-NAME;
    say q:to/END-USAGE/;
    Reads the meta-data for a given DB schema and generates code that implements a set of REST APIs for the tables in that schema. The application 
    recognizes most db types and foreign keys.

        --app - Generate the Bailador app that implements the REST APIs.
    
        --mods - Generate empty Class modules that can be modified by users (one to implement each role).
    
        --roles - Generate roles implemented by the modules (one for each table in the schema).
    
        --templates - Generate HTML template interface.
    
        --list - List the DB schemas.
    
        --dbname=[db name] - Defaults to value of ENV Var DB_NAME.

        --host=[db host name] - Defaults to value of ENV Var DB_HOST.

        --port=[db port number] - Defaults to value of ENV Var DB_PORT.

        --user=[db user name] - Defaults to value of ENV Var DB_USER.

        --pass=[db user password] - Defaults to value of ENV Var DB_PASSWORD.

        --schema=[schema name] - Defaults to 'public'. Defaults to ENV Var DB_SCHEMA.

        --prefix=[prefix name] - Defaults to the schema name.

        --app-host=[host name] - Defaults to value of ENV Var APP_HOST.

        --app-port=[port number] - Defaults to value of ENV Var APP_PORT.
    
        --help - Displays this message.
    END-USAGE
    exit;
}



sub MAIN( Bool :$app=False, Bool :$mods=False, Bool :$roles=False, Bool :$templates=False, 
          Bool :$list=False, Str :$db-type, Str :$dbname=%*ENV<DB_NAME>, Str :$host=%*ENV<DB_HOST>, 
          Str :$port=$*ENV<DB_PORT>, Str :$user=%*ENV<DB_USER>,
          Str :$password=%*ENV<DB_PASSWORD>, Str :$schema='public', Str :$prefix = 'public', 
          Str :$app-host=$*ENV<APP_HOST>, Str :$app-port=$*ENV<APP_PORT>, Bool :$help=False ) {

    # our $conninfo = join " ",
    #     ('dbname=' ~ ($dbname || die("missing DB_NAME in environment"))),
    #     ("host=$host"),
    #     ("port=$port"),
    #     ("user=$user"),
    #     ("password=$password");
    # $pg = DB::Pg.new(:$conninfo);

    my $db = API::Db.new(db-type => $db-type, dbname => $dbname, host => $host, port => $port, 
                        user => $user, password => $password);
    say $db.query-hash.keys;
    my $db-type-conv = API::Db::Conv.new(db => $db-type);

    usage()                         if $help;
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
        ("password=$_" with %*ENV<DB_PASSWORD>);/;

    make_roles($schema, $db-type-conv, $prefix, $db-type, $meta-conn, %tables) if $roles;
    make_templates( $schema, $prefix, $db-type, $app-host, $app-port, %tables ) if $templates;
    make_dockerfile( $db-base-name, $app-port ) if $app;
    make_envfile( $dbname, $db-type, $host, $port, $user, $password, $app-host, $app-port ) if $app;
}
