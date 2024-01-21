#!/usr/bin/env raku

#use lib "lib";
use DB::Pg;
use JSON::Pretty;
use Getopt::Long;
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

sub list-schemas-and-exit {
    # list the schemas
    say "Schemas : ";
    our $i = 0;
    our %schemas;
    for $pg.query('select schema_name from information_schema.schemata').hashes -> %h {
        
        for %h.kv -> $key, $value {
            say  ++$i ~ ' : ' ~ ($value || '<NULL>');
            %schemas{$i} = $value;
            #say "setting $i to " ~ %schemas<$i>;
        }
    }
    exit;
    #our $schema = 0;
    #while ($i < $schema || $schema < 1) {
        #say "Choose a schema number : ";
        #$schema = Int(get);
        #say "Reading schema : $schema => " ~ %schemas{$schema};
    #}
}

sub check-schema-name ($schema) {
    my $schema-exists = False;
    for $pg.query( 'select schema_name from information_schema.schemata where schema_name=$1', $schema ) -> $result {
        if $result eq $schema {
            $schema-exists = True;
        }
    }
    die "No Such Schema $schema\nUse '--list' to show valid schemas." unless $schema-exists;
}

sub get-tables ($schema) {
    our %tables;
    for $pg.query('select table_name from information_schema.tables where table_type = $1 and table_schema = $2', 
        'BASE TABLE', $schema ).hashes -> %h {
        for %h.kv -> $key, $value {
            for $pg.query('select a.column_name, a.data_type, a.column_default, a.is_nullable, c.table_name as references_table, c.column_name as references_column from information_schema.columns a left join information_schema.key_column_usage b on (b.column_name=a.column_name and b.table_name=a.table_name and b.constraint_name~$1) left join information_schema.constraint_column_usage c on (c.constraint_name=b.constraint_name)where a.table_name=$2 and a.table_schema=$3',
                '_fkey$', $value, $schema).hashes -> %c {
                push %tables{$value}, %c;
            }
        }
    }
    return %tables;
}

sub MAIN( Bool :$app=False, Bool :$mods=False, Bool :$roles=False, Bool :$templates=False, 
          Bool :$list=False, Str :$dbname=%*ENV<DB_NAME>, Str :$host=%*ENV<DB_HOST>, 
          Str :$port=$*ENV<DB_PORT>, Str :$user=%*ENV<DB_USER>,
          Str :$password=%*ENV<DB_PASSWORD>, Str :$schema='public', Str :$prefix = 'public', 
          Str :$app-host=$*ENV<APP_HOST>, Str :$app-port=$*ENV<APP_PORT>, Bool :$help=False ) {

    our $conninfo = join " ",
        ('dbname=' ~ ($dbname || die("missing DB_NAME in environment"))),
        ("host=$host"),
        ("port=$port"),
        ("user=$user"),
        ("password=$password");
    $pg = DB::Pg.new(:$conninfo);

    usage()                     if $help;
    list-schemas-and-exit       if $list;
    check-schema-name ($schema) if $schema ne 'public';

    our %tables = get-tables( $schema );
    say to-json %tables;
    unless defined($prefix) { $prefix = $schema.tc }
    
    make_app($dbname, $schema, $prefix, %tables) if $app;
    make_mods($schema, $prefix, %tables) if $mods;

    my $meta-conn = q/my $conninfo = join " ",
        ('dbname=' ~ (%*ENV<DB_NAME> || die("missing DB_NAME in environment"))),
        ("host=$_" with %*ENV<DB_HOST>),
        ("port=$_" with %*ENV<DB_PORT>),
        ("user=$_" with %*ENV<DB_USER>),
        ("password=$_" with %*ENV<DB_PASSWORD>);/;

    make_roles($schema, $prefix, $meta-conn, %tables) if $roles;
    make_templates( $schema, $prefix, $app-host, $app-port, %tables ) if $templates;
    make_dockerfile( $dbname, $app-port ) if $app;
    make_envfile( $dbname, $host, $port, $user, $password, $app-host, $app-port ) if $app;
}
