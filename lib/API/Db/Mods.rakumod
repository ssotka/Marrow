unit module Mods;

sub make_mods ( $schema, $prefix, %tables ) is export {
    for %tables.kv -> $table, @columns {
        my $dir = "results/lib/{$prefix}/{$table}.rakumod".IO.dirname;
        $dir.IO.mkdir unless $dir.IO.e;
        my $fh = "results/lib/{$prefix}/{$table}.rakumod".IO.open(:w);
        $fh.say: "use " ~ $prefix ~ "::roles::{$table};";
        $fh.say;
        $fh.say: 'class ' ~ $prefix ~ '::' ~ $table ~ ' does ' ~ $prefix ~ '::roles::' ~ $table ~ ' {';
        $fh.say: '   # Make any changes here';
        $fh.say: '}';
    }

}