unit module Dockerfile;

sub make_dockerfile($dbname, $app-port) is export {
    my $dockerfile = "resources/DOCKERFILE.tmpl".IO.slurp;
    my $dockerfile-out = "Dockerfile".IO.open(:w);
    $dockerfile-out.say: $dockerfile.subst( '%%DB_NAME%%', $dbname, :g).subst( '%%APP_PORT%%', $app-port, :g);
    $dockerfile-out.close;
}

sub make_envfile( Str $dbname, Str $db-type, Str $host , Str $port, Str $user, 
                  Str $pass, Str $app-host , Str $app-port ) is export {
    my $envfile = ".env".IO.open(:w);
    my $final-host = $host;
    if $host eq 'localhost' or $host eq '127.0.0.1' {
        $final-host = 'host.docker.internal';
    }

    my $final-app-host = $app-host;
    if $app-host eq 'localhost' or $app-host eq '127.0.0.1' {
        $final-app-host = '0.0.0.0';
    }

    $envfile.say: qq:to/EOF/;
        DB_NAME=$dbname
        DB_TYPE=$db-type
        DB_HOST=$final-host
        DB_PORT=$port
        DB_USER=$user
        DB_PASS=$pass
        APP_HOST=$final-app-host
        APP_PORT=$app-port
        EOF
    $envfile.close;
}