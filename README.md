NAME
====

Marrow - MRO, the opposite of ORM.

SYNOPSIS
========

```
bin/mro.raku [--app] [--mods] [--roles] [--templates] [--list] [--dbname=<Str>] [--host=<Str>] [--user=<Str>] [--password=<Str>] [--schema=<Str>] [--prefix=<Str>] [--help]

--app       : Generate the Cro main application and default routes.

--mods      : Generate the objects representing the DB tables.

--roles     : Generate the roles for the objects which define the basic methods of the objects.

--templates : Generate the index.html file for the Cro app which can be used for testing the APIs.

--list      : List the schemas available in the DB.

--prefix    : By default the Objects will name following this format {prefix}::{table}. By default prefix is the same as the schema name. 
```

DESCRIPTION
===========

Marrow (mro.raku) is an application that will, when pointed at a standards compliant SQL relational database (at the moment only Postgresql is supported) will interrogate the the given schema's tables (defaults to public) and their relationships. It will then generate a Cro application to serve APIs to manipulate those tables. 

The code generated includes a set of object libraries and roles for those objects. The basic functionaliry for the objects are in the corresponding roles which the objects implement. User-written code should go into the object file itself. That way when the DB is altered the use may regenerate just the roles and templates to have them updated.

The new Cro application will be created in the results directory and will be set up in the following tree:

```
resources
    bin
        <dbname>.raku (Cro application)
    lib
        prefix
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
* Move DB connection code to a single module in the generated app.
* Generate a Dockerfile for generated app.
   

AUTHOR
======

Scott Sotka <ssotka@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Scott Sotka

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

