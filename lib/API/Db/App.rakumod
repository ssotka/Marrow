unit module App;
use API::Db::Conv;

            
sub make_app (Str $dbname, $db-type-conv, Str $schema, Str $prefix, %tables ) is export {

    # Create a file for user defined routes
    'results/lib'.IO.mkdir unless 'results/lib'.IO.e;

    unless "results/lib/{$dbname}-routes.rakumod".IO.e {
        my $fh = "results/lib/{$dbname}-routes.rakumod".IO.open: :w ;
        $fh.say: qq:to/END/;
        unit module {$dbname}-routes;
        use Cro::HTTP::Router;
        use LibUUID;
        use JSON::Fast;

        # Will only be generated if this file does not exist

        sub user-defined-routes() is export \{
            route \{
                # Your API routes go here...
                # get -> \{ ... }
                # get -> uint32 \$id \{ ... \}
                # ...
                get -> 'ping' \{
                    my \%o = result => 'SUCCESS', message => 'pong';
                    content 'application/json', to-json \%o;
                }
            }
        }
        END
        $fh.close;
    }

    # Create a file for the schema routes
    "results/lib/{$prefix}".IO.mkdir unless "results/lib/{$prefix}".IO.e;
    my $srh = "results/lib/{$prefix}/{$schema}-routes.rakumod".IO.open(:w);
    $srh.say: qq:to/END/;
    unit module {$prefix}::{$schema}-routes;
    use Cro::HTTP::Router;
    use LibUUID;
    use JSON::Fast;

    sub {$schema}-routes() is export \{
        route \{
    END

    # Create GET POST PUT routes for each table
    for %tables.kv -> $table, @columns {
        next if $table eq 'sqlite_sequence';
        $srh.say: qq:to/END/;

                use {$prefix}::{$table};
                get -> '$table',\$id \{
                    say \$*ERR: "GOT ID: \$id";
                    my \$starttime = now;
                    my \%o;
                    try \{
                        my \${$table} = {$prefix}::{$table}\.new( id => \$id );
                        %o = 
        END
        # set the values for each column if they are defined
        for @columns -> %col {
            $srh.say: '             ' ~ %col<column_name> ~ ' => defined($' ~ $table ~ '.' ~ %col<column_name> ~ ') ?? $' ~ $table ~ '.' ~ %col<column_name> ~ '.Str !! "",';
        }
        $srh.say: q:to/END/;
                        ;
                    }
                    if $! {
                        %o = 
                            result => "FAILURE",
                            message => $!.message 
                        ;
                    }
                    %o<elapsed> = (now - $starttime).Rat;
                    content 'application/json', to-json %o;
                }

        END

        $srh.say: qq:to/END/;
                post -> '{$table}'  \{
                    request-body -> \%args \{
                    my \$starttime = now;
                    my \${$table} = {$prefix}::{$table}.new( );
        END

        for @columns -> %col {
            next if %col<column_name> eq 'id' | 'created' | 'last_modified';
            #say %col<column_name> ~ ' ' ~ %col<data_type> ~ ' -> ' ~ $db-type-conv.type(%col<data_type>.lc.subst(/'(' \d+ ')'/, ""));
            if $db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) eq 'Str' {
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( %args<' ~ %col<column_name> ~ '> );';
            }
            elsif defined $db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") )  {
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( ' ~ $db-type-conv.type(%col<data_type>.lc.subst(/'(' \d+ ')'/, "")) ~ '.new( %args<' ~ %col<column_name> ~ '> ) );';
            }
            else{
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( %args<' ~ %col<column_name> ~ '> );';
            }
        }
        $srh.say: qq:to/END/;
                    \${$table}.save;
                    my \%res = result => 'SUCCESS', id => \${$table}.id.Str, elapsed => (now - \$starttime).Rat;
                    content 'application/json', to-json \%res;
                    \}
                \}
                
                put -> '{$table}' \{
                    request-body -> \%args \{
                    my \$starttime = now;
                    my \${$table} = {$prefix}::{$table}.new\( id => \%args<id> \);
        END
        for @columns -> %col {
            next if %col<column_name> eq 'created' | 'last_modified';
            #say %col<column_name> ~ ' ' ~ %col<data_type> ~ ' -> ' ~ $db-type-conv.type(%col<data_type>);
            if $db-type-conv.type( %col<data_type>.lc.subst(/'(' \d+ ')'/, "") ) eq 'Str' {
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( %args<' ~ %col<column_name> ~ '> );';
            }
            elsif defined $db-type-conv.type(%col<data_type>) {
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( ' ~ $db-type-conv.type(%col<data_type>) ~ '.new( %args<' ~ %col<column_name> ~ '> ) );';
            }
            else{
                $srh.say: '             $' ~ $table ~ '.' ~ %col<column_name> ~ '( %args<' ~ %col<column_name> ~ '> );';
            }
        }
        $srh.say: qq:to/END/;
                    \${$table}.save;
                    my \%res = result => 'SUCCESS', id => \${$table}.id.Str, elapsed => (now - \$starttime).Rat;
                    content 'application/json', to-json \%res;
                    \}
                \}

        END
    }
    $srh.say: q:to/END/;
            }
        }
    END
    $srh.close;


    # Create the Cro app which includes the 
    'results/bin'.IO.mkdir unless 'results/bin'.IO.e;

    my $bfh = "results/bin/{$dbname}.raku".IO.open(:w);
    # Bailador REST API head
    $bfh.say: q:to/END/;
    #!/usr/bin/env raku;
    use lib 'lib';

    use Cro::HTTP::Server;
    use Cro::HTTP::Router;
    use LibUUID;
    use JSON::Fast;
    
    END

    $bfh.say: "use {$dbname}-routes;";
    $bfh.say: "use {$prefix}::{$schema}-routes;";
    
    $bfh.say: q:to/END/;
    # Create the application basic routes. Include the user defined routes
    # in a separate file lib/{$appname)-routes.rakumod
    my $application = route {
        get -> 'index.html' {
            my $index = 'resources/templates/html/index.html';
            my $result = $index.IO.slurp;
            content 'text/html', $result;
        }

    END

    

    # Finish the app
    $bfh.say: "     include {$schema}-routes;";
    $bfh.say: "     include user-defined-routes;";
    $bfh.say: q:to/END/;
    }
    # Create the HTTP service object
    my Cro::Service $service = Cro::HTTP::Server.new(
        :host(%*ENV<APP_HOST>), :port(%*ENV<APP_PORT>), :$application
    );
    
    # Run it
    $service.start;

    # Cleanly shut down on Ctrl-C
    react whenever signal(SIGINT) {
        say "Got SIGINT, shutting down...";
        $service.stop;
        exit;
    };
    END
    $bfh.close;
}

