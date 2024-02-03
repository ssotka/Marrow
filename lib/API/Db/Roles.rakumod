unit module Roles;

use API::Db::Conv;

sub make_db_conn ( $prefix ) is export {
    my $dir = "results/lib/{$prefix}";
    $dir.IO.mkdir ; #unless $dir.IO.e;
    my $fh = "results/lib/{$prefix}/db.rakumod".IO.open :w;#|| die "Could not open file: {$!}";
    $fh.say: q:to/END/;
    use DB::Pg;
    use DB::SQLite;
    use LibUUID;
    use Debug;
    END
    $fh.say: "role {$prefix}::db \{";
    $fh.say: q:to/END/;
        has $.dbh is rw;
        has $.conninfo is rw;

        method connect() {
            $.conninfo = join " ",
            ("dbname=%*ENV<DB_NAME>"),
            ("host=%*ENV<DB_HOST>"),
            ("port=%*ENV<DB_PORT>"),
            ("user=%*ENV<DB_USER>"),
            ("password=%*ENV<DB_PASS>");

            given %*ENV<DB_TYPE> {
                when 'pg'     { $.dbh = DB::Pg.new(conninfo => self.conninfo); }
                when 'sqlite' { $.dbh = DB::SQLite.new(filename => %*ENV<DB_NAME>); }
                when 'mysql'  { die "MySQL not yet supported"; }
                when 'oracle' { die "Oracle not yet supported"; }
            }
        }

        method get-db-handle() is export {
            self.connect() unless $.dbh;
            return $.dbh;
        }
    }
    END
    $fh.close;
}

sub make_roles ( $schema, $db-type-conv, $prefix, $db-type, $meta_conn, %tables ) is export {

    for %tables.kv -> $table, @columns {
        next if $table eq 'sqlite_sequence';

        my $table-full-name = $db-type eq 'sqlite' ?? $table !! "{$schema}.{$table}";

        my $dir = "results/lib/{$prefix}/roles/{$table}.rakumod".IO.dirname;
        $dir.IO.mkdir unless $dir.IO.e;

        #my $fh = "results/lib/{$prefix}/{$table}.rakumod".IO.open(:w);
        my $fh = "results/lib/{$prefix}/roles/{$table}.rakumod".IO.open(:w);

        $fh.say: qq:to/END/;
            use DB::Pg;
            use LibUUID;
            use Debug;
            use {$prefix}::db;
            
            role {$prefix}::roles::{$table} does {$prefix}::db does Debug \{
                has Str \$.table = "{$schema}.{$table}";
            END
        for @columns -> %col {
            $fh.say: '   has ' ~ ($db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) || 'Str') ~ ' $.' ~ %col<column_name> ~ ' is rw;';
            #$fh.say: '   has Bool $._' ~ %col<column_name> ~ '_chgd is rw = False;';
        }
        $fh.say: "\n";
        $fh.say: '   my $db;';
        $fh.say: '   has %!changed_fields = (';
        for @columns -> %col {
            $fh.say: '      ' ~ %col<column_name> ~ ' => False,';
        }
        $fh.say: '   );';
        $fh.say: "\n";
        
        $fh.say: '   has @!required_fields = (';
        for @columns -> %col {
            if %col<is_nullable> eq 'NO' and ! defined(%col<column_default>) {
                $fh.say: '      \'' ~ %col<column_name> ~ '\',';
            }
        }
        $fh.say: '   );';
        $fh.say: "\n";

        $fh.say: '   submethod BUILD(:$id) {';
        $fh.say: '      try {';
        $fh.say: '         $db = self.get-db-handle();';
        $fh.say: '         for $db.query(\'select * from ' ~ $table-full-name ~ ' where id=$1\',$id).hashes -> %h {';
        for @columns -> %col {
            if $db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) ne 'Rat' {
                $fh.say: '            $!' ~ %col<column_name> ~ ' = %h<' ~ %col<column_name>~ '>.' ~ ($db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) || 'Str') ~ ';';
            }
            else { 
                $fh.say: '            $!' ~ %col<column_name> ~ ' = %h<' ~ %col<column_name>~ '>.Rat;';
            }
        }
        $fh.say: '         }';
        $fh.say: '      } ';
        $fh.say: '      if $! { self.debug("Failed lookup of ' ~ $table ~ ': $id - $!"); die "Failed lookup of ' ~ $table ~ ': $id : $!"; } ';
        #$fh.say: '      say $*ERR: "Finished BUILD";';
        $fh.say: '   }';
        for @columns -> %col {
            $fh.say: "\n";
            $fh.say: '   multi method ' ~ %col<column_name> ~ '() { $!' ~ %col<column_name> ~ ' };';
            $fh.say: '   multi method ' ~ %col<column_name> ~ '( ' ~ ($db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) || 'Str') ~
                    ' $' ~ %col<column_name> ~ ' ) { ';
            if %col<column_name> eq 'id' {
                $fh.say: '      if ! defined($!id) {';
            }
            $fh.say: '         $!' ~ %col<column_name> ~ ' = $' ~ %col<column_name> ~ ';' ~
                "\n         " ~ '%!changed_fields<' ~ %col<column_name> ~ '> = True; ' ~ "\n" ~ '   };';
            if %col<column_name> eq 'id' {
                $fh.say: '   };';
            }
            if  defined(%col<references_table>) && %col<data_type> eq 'uuid' && %col<column_name> ne 'id' {
                $fh.say: '   method ' ~ %col<column_name> ~ '_inflate() {';

                if %col<references_table> ne $table {
                    $fh.say: '      use ' ~ $prefix ~ '::' ~ %col<references_table> ~ ';';
                }

                $fh.say: qq:to/END/;
                        my \$t = {$prefix}::{%col<references_table>}.new( id => \$.{%col<column_name>} );
                        return \$t;
                    }
                
                    multi method {$table}_list(:\${%col<column_name>} ) \{
                        my \@list;
                        my \$q = 'select id from {$table} where {%col<column_name>}=\$1';
                        for \$db.query(\$q, \${%col<column_name>}).hashes -> \%st \{
                            \@list.push( {$prefix}::{%col<references_table>}.new( id => \%st<id> ));
                        }
                        return \@list;
                    }
                END
            }
        }
        $fh.say: qq:to/END/;
            method save() \{
                if \$!id \{
                    my \@upd_list;
                    my \@upd_args;
                    my \$q = "UPDATE {$table-full-name} set ";
                    my \$index=1;
        END
        my $index = 1;
        for @columns -> $col {
            $fh.say: qq:to/END/;
                    if \%!changed_fields<{$col<column_name>}> \{
                        \@upd_list.push( '{$col<column_name>} = \$' ~ \$index++ );
                        \@upd_args.push( \$!{$col<column_name>}.{ $db-type-conv.type( $col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) } );
                    }
            END
        }
        $fh.say: qq:to/END/;
                    my \$update = join ',', \@upd_list;
                    my \$where = ' WHERE id = \$' ~ \$index  ;
                    \@upd_args.push( \$!id );
                    my \$query = \$q ~ \$update ~ \$where;
                    try \{
                        self.debug( \$query );
                        \$db.query(\$query, |\@upd_args);
                        for self.changed_list() -> \$key \{
                            \%!changed_fields\{ \$key \} = False;
                        \}
                    \}
                    if \$! \{ self.debug("Failed update of {$table}: \$!id - \$!"); die "Failed update of {$table}: \$!id -- \$!"; \}
                \}
                else \{
                    my \@upd_list;
                    my \@vals;
                    my \@upd_args;
                    my \$q = "INSERT into {$table-full-name} ";
                    my \$index=1;
        END

        for @columns -> $col {
            $fh.say: qq:to/END/;
                    if \%!changed_fields<{$col<column_name>}> \{
                        \@upd_list.push( '{$col<column_name>}' );
                        \@vals.push( '\$' ~ \$index++ );
                        \@upd_args.push( \$!{$col<column_name>}.{ $db-type-conv.type( $col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) } );
                    }
            END
        }
        $fh.say: qq:to/END/;
                    my \$cols = join ',', \@upd_list;
                    my \$vals = join ',', \@vals;
                    if \@!required_fields ⊆ self.changed_list() \{
                        my \$query = \$q ~ "(" ~ \$cols ~ ") values (" ~ \$vals ~ ") RETURNING id;";
                        try \{
                            self.debug( \$query );
                            \$!id = \$db.query(\$query, |\@upd_args).value;
                            for self.changed_list() -> \$key \{
                                \%!changed_fields\{ \$key \} = False;
                            \}
                        \}
                        if \$! \{ self.debug("Failed insert into {$table},"); die "Failed insert into {$table}."; \}
                    \}
                    else \{
                        self.debug( "missing required fields: " ~ \@!required_fields (-) self.changed_list() );
                        die "missing required fields: " ~ \@!required_fields (-) self.changed_list();
                    \}
                \}
            \}

        END
        
        $fh.say: qq:to/END/;
            method changed_list() \{
                my \@list;
                for \%!changed_fields.keys -> \$key \{
                    if \%!changed_fields\{ \$key \} \{
                        \@list.push\( \$key \);
                    \}
                \}
                return \@list;
            \}
        \}
        END
        $fh.close;
    }
    
    "results/lib/Debug.rakumod".IO.spurt: q:to/END/;
    role Debug {
        method debug ( $msg ) {
            say $msg;
        }
    }
    END
}
