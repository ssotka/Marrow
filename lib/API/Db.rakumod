unit class API::Db:ver<0.0.1>;

use DB::Pg;
use DB::SQLite;

class API::Db {
    has $.dbname;
    has $.host;
    has $.port;
    has $.user;
    has $.password;
    has $.db-type;
    has $.dbh is rw;
    has $.i;
    has %.schemas is rw;
    has $.schema is rw;
    has %.tables is rw;
    has $.conninfo is rw;
    has %.query-hash is rw;

    method TWEAK {
        $.conninfo = join " ",
        ('dbname=' ~ ($.dbname || die("missing DB_NAME in environment"))),
        ("host=$.host"),
        ("port=$.port"),
        ("user=$.user"),
        ("password=$.password");

        given $.db-type {
            when 'pg'     { self.dbh = DB::Pg.new(conninfo => self.conninfo); }
            when 'sqlite' { self.dbh = DB::SQLite.new(filename => $.dbname); }
            when 'mysql'  { die "MySQL not yet supported"; }
            when 'oracle' { die "Oracle not yet supported"; }
        }

        %.query-hash = (
            pg => {
                    list-schemas      => 'select schema_name from information_schema.schemata',
                    check-schema-name => q<<
                        select schema_name 
                        from information_schema.schemata 
                        where schema_name=$1 >>,
                    get-tables        => q<<
                        select table_name 
                        from information_schema.tables 
                        where table_type = $1 and table_schema = $2 >>,
                    get-columns       => q<<
                        select a.column_name, a.data_type, a.column_default, a.is_nullable, 
                            c.table_name as references_table, c.column_name as references_column 
                        from information_schema.columns a 
                            left join information_schema.key_column_usage b on (b.column_name=a.column_name and b.table_name=a.table_name and b.constraint_name~$1) 
                            left join information_schema.constraint_column_usage c on (c.constraint_name=b.constraint_name)
                        where a.table_name=$2 and a.table_schema=$3 >>,
                    list-foreign-keys => 'select a.column_name, a.data_type, a.column_default, a.is_nullable, c.table_name as references_table, c.column_name as references_column from information_schema.columns a left join information_schema.key_column_usage b on (b.column_name=a.column_name and b.table_name=a.table_name and b.constraint_name~$1) left join information_schema.constraint_column_usage c on (c.constraint_name=b.constraint_name)where a.table_name=$2 and a.table_schema=$3',
                },
            sqlite =>
                {
                    list-schemas => 'select schema_name from information_schema.schemata',
                    check-schema-name => q<<
                        select schema_name 
                        from information_schema.schemata 
                        where schema_name=$1 >>,
                    get-tables  => q<<select name as table_name from sqlite_schema where type='table'>>,
                    get-columns => q<<SELECT name as column_name, type as data_type, dflt_value as column_default, "notnull" as is_nullable,"table" as references_table, "to" as references_column FROM PRAGMA_TABLE_INFO($1) a left join PRAGMA_FOREIGN_KEY_LIST($2) b on (b."from"=a."name")>>,
                        # select a.column_name, a.data_type, a.column_default, a.is_nullable,
                        #     c.table_name as references_table, c.column_name as references_column 
                        # from information_schema.columns a 
                        #     left join information_schema.key_column_usage b on (b.column_name=a.column_name and b.table_name=a.table_name and b.constraint_name~$1) 
                        #     left join information_schema.constraint_column_usage c on (c.constraint_name=b.constraint_name)
                        # where a.table_name=$2 and a.table_schema=$3 >>,
                    list-foreign-keys => 'select a.column_name, a.data_type, a.column_default, a.is_nullable, c.table_name as references_table, c.column_name as references_column from information_schema.columns a left join information_schema.key_column_usage b on (b.column_name=a.column_name and b.table_name=a.table_name and b.constraint_name~$1) left join information_schema.constraint_column_usage c on (c.constraint_name=b.constraint_name)where a.table_name=$2 and a.table_schema=$3',
                }
        );
    }

    method get-db-handle {
        return $.dbh;
    }
    
    method list-schemas-and-exit  {
        # list the schemas
        say "Schemas : ";
        our $i = 0;
        our %schemas;
        say "DB-Type: " ~ $.db-type;
        for $.dbh.query(%.query-hash{$.db-type;'list-schemas'}.Str).hashes -> %h {
            
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

    method check-schema-name ($schema) {
        my $schema-exists = False;
        for $.dbh.query( %.query-hash{$.db-type; 'check-schema-name'}.Str, $schema ) -> $result {
            if $result eq $schema {
                $schema-exists = True;
            }
        }
        die "No Such Schema $schema\nUse '--list' to show valid schemas." unless $schema-exists;
    }

    sub get-args ($db-type, $query-type, $regex, $table, $schema) {
        my @args;
        given $db-type {
            when 'pg' {
                when $query-type eq 'get-columns' {
                    @args = ( $regex, $table, $schema );
                }
                when $query-type eq 'get-tables' {
                    @args = ( 'BASE TABLE', $schema );
                }
            }
            when 'sqlite' {
                when $query-type eq 'get-columns' {
                    @args = ( $table, $table );
                }
                when $query-type eq 'get-tables' {
                    @args = ();
                }
            }
        }
        return @args;
    }
    method get-tables ($schema) {
        our %tables;
        say $.dbh;
        say "Query: " ~ %.query-hash{$.db-type; 'get-tables'}.Str;
        for $.dbh.query( %.query-hash{$.db-type; 'get-tables'}.Str,  
            get-args($.db-type, 'get-tables', 'BASE TABLE', $schema, Nil )).hashes -> %h {
            for %h.kv -> $key, $value {
                say "key: $key, value: $value";
                say "Query: " ~ %.query-hash{$.db-type; 'get-columns'}.Str;

                for $.dbh.query( %.query-hash{$.db-type; 'get-columns'}.Str, 
                    get-args($.db-type,'get-columns','_fkey$', $value, $schema)).hashes -> %c {
                    push %tables{$value}, %c;
                }
            }
        }
        return %tables;
    }
}