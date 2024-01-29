unit class API::Db::Conv;
# Set up type conversions from the variouse DB types to raku types
# The conversion will be set specific to the DB type.

# our %types = 'uuid'                       => 'UUID',
#             'boolean'                     => 'Bool',
#             'text'                        => 'Str',
#             'integer'                     => 'Int',
#             'timestamp without time zone' => 'DateTime',
#             'numeric'                     => 'Real',
#             'money'                       => 'Real',
#             'email'                       => 'email',
#             'product_format'              => 'Str',
#             'USER-DEFINED'                => 'Str',
#             'date'                        => 'Date',
#             'character varying'           => 'Str',
#             ;

class X::API::DB::Conv::Unknown is Exception {
    has $.type;
    method message() {
        "Unknown type: $.type";
    }
}

class API::Db::Conv {
    has Str $.db;
    has %!types;
    submethod TWEAK {
        given $!db {
            when 'pg' {
                %!types = 
                        'uuid'                        => 'UUID',
                        'boolean'                     => 'Bool',
                        'text'                        => 'Str',
                        'integer'                     => 'Int',
                        'timestamp without time zone' => 'DateTime',
                        'numeric'                     => 'Real',
                        'money'                       => 'Real',
                        'email'                       => 'email',
                        'product_format'              => 'Str',
                        'USER-DEFINED'                => 'Str',
                        'date'                        => 'Date',
                        'character varying'           => 'Str',
                        ;
            }

            when 'mysql' {
                %!types = 
                        'uuid'                        => 'UUID',
                        'boolean'                     => 'Bool',
                        'text'                        => 'Str',
                        'integer'                     => 'Int',
                        'timestamp without time zone' => 'DateTime',
                        'numeric'                     => 'Real',
                        'money'                       => 'Real',
                        'email'                       => 'email',
                        'product_format'              => 'Str',
                        'USER-DEFINED'                => 'Str',
                        'date'                        => 'Date',
                        'character varying'           => 'Str',
                        ;
            }
                
            when 'sqlite' {
                %!types = 
                        'uuid'                        => 'Str',
                        'boolean'                     => 'Int',
                        'text'                        => 'Str',
                        'integer'                     => 'Int',
                        'timestamp without time zone' => 'Str',
                        'numeric'                     => 'Real',
                        'money'                       => 'Real',
                        'email'                       => 'Str',
                        'product_format'              => 'Str',
                        'USER-DEFINED'                => 'Str',
                        'date'                        => 'Str',
                        'character varying'           => 'Str',
                        ;
            }
            default {
                die X::API::DB::Conv::Unknown.new(:type($!db));
                #die "Unknown DB type: $!db";
            }
        }
    }

    method type(Str $type) {
        unless %!types{$type.lc} {
            die X::API::DB::Conv::Unknown.new(:type($type));
            #die "Unknown type: $type";
        }
        return %!types{$type.lc};
    }
}