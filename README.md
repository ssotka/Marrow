NAME
====

Marrow - MRO, the opposite of ORM.

SYNOPSIS
========

```
Usage:
  ./bin/mro.raku [--app] [--mods] [--roles] [--templates] [--list] [--db-type=<Str>] [--dbname=<Str>] [--host=<Str>] [--port=<Str>] [--user=<Str>] [--password=<Str>] [--schema=<Str>] [--prefix=<Str>] [--app-host=<Str>] [--app-port=<Str>] [--help]
  
    --app               Generate the Cro app that implements the REST APIs. [default: False]
    --mods              Generate empty Class modules that can be modified by users (one to implement each role). [default: False]
    --roles             Generate roles implemented by the modules (one for each table in the schema). [default: False]
    --templates         Generate HTML template interface. [default: False]
    --list              List the DB schemas (postgreSQL only) [default: False]
    --db-type=<Str>     The type of database (sqlite, pg, mysql, etc).
    --dbname=<Str>      The name of the database - env DB_NAME (filename for SQLite).
    --host=<Str>        The host name of the database - env DB_HOST.
    --port=<Str>        The port number of the database - env DB_PORT.
    --user=<Str>        The user name for the database - env DB_USER.
    --password=<Str>    The password for the database - env DB_PASS.
    --schema=<Str>      The name of the schema to use. [default: 'public']
    --prefix=<Str>      The library prefix to use for the generated code. [default: 'public']
    --app-host=<Str>    The host name for the app - env APP_HOST.
    --app-port=<Str>    The port number for the app - env APP_PORT.
    --help              Displays this message. [default: False]
```

DESCRIPTION
===========

Marrow (mro.raku) is an application that will, when pointed at a standards compliant SQL relational database which supports the Information Schema (at the moment only Postgresql and SQLite are supported) will interrogate the the given schema's tables (defaults to public) and their relationships. It will then generate a Cro application to serve APIs to manipulate those tables. 

```Note: At the moment mro requires all the tables to have a field called "id" as the primary key. It has been tested with "id" values of integer and uuid.```

The code generated includes a set of object libraries and roles for those objects. The basic functionaliry for the objects are in the corresponding roles which the objects implement. User-written code should go into the object file itself. That way when the DB is altered the use may regenerate just the roles and templates to have them updated.

Also emitted at this time are a Dockerfile and .env file for the application. The .env file will look like so:
```
# host generally needs to be 0.0.0.0 for docker
APP_HOST=0.0.0.0  
APP_PORT=2314
DB_NAME=api_test
DB_PASSWORD=<yeah-right>
DB_USER=ssotka
# This is for a database running on the current maching. YMMV.
DB_HOST=host.docker.internal
DB_PORT=5432
```

Assuming you have docker installed locally the Dockerfile can be built and run like so:

```
> docker build -f ./Dockerfile -traku-test:new .
> docker run -i -p 127.0.0.1:2314:2314 --env-file ./.env raku-test:new
```

The new Cro application will be created in the results directory and will be set up in the following tree:

```
results
    bin
        <dbname>.raku (Cro application)
    lib
        <prefix>
            roles
                <roles for object files (roles)>
            <object files (mods)>
        <user defined routes module>
    resouces
        templates
            html
                index.html
```

TO-DO
=====
* Move boilerplate to templating system (find a templating system).
* Implement a security layer for the routes.
   
Dependencies
============
This app requires libpq and libuuid (ossp-uuid) be installed.

`macOS`: DB::Pg has trouble installing on MacOS. This is because the libpq on MacOS that is installed by Homebrew does not match the version defined by the module. This problem can be worked around by doing the following:

```
> git clone https://github.com/CurtTilmes/raku-dbpg.git
> cd raku-dbpg;
> sed -i '.bk' -e 's/\:ver\<5\>//g'  META6.json;
> zef install --exclude="pq" .
```

You may then install this application and things should work.

AUTHOR
======

Scott Sotka <ssotka@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2024 Scott Sotka

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

