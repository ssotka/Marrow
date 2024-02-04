use Test;
use lib 'lib';

use DB::SQLite;
use API::Db;

# create a new sqlite database using api_test_sqlte.sql
my $filename = 't/02-db.sqlite';
ok( my $db = DB::SQLite.new(:$filename), 'create a new sqlite database');

# create the schema
my $schema = 't/api_test_sqlite.sql'.IO.slurp;
ok( $db.execute($schema), 'create the schema');

# create a new API::Db object
ok( my $api = API::Db.new(dbname => $filename, 
                          host => 'localhost',
                          port => 5432,
                          user => 'test',
                          password => 'test',
                          db-type => 'sqlite'), 'create a new API::Db object');

# get a connection to the database
ok( my $dbh = $api.get-db-handle, 'get a connection to the database');

# list the tables in the database
ok( my @tables = $api.get-tables('public'), 'list the tables in the database');

#remove the database file
ok( unlink($filename), 'remove the database file');

done-testing;
