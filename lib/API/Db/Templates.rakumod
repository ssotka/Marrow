unit module Templates;

sub make_templates ( $schema, $prefix, $db-type, $app-host, $app-port, %tables ) is export {
    my $dir = "results/resources/templates/html/index.html".IO.dirname;
    $dir.IO.mkdir unless $dir.IO.e;
    my $tfh = "results/resources/templates/html/index.html".IO.open(:w);
    $tfh.say: q:to/END3/; 
    <html>
    <header>

    </header>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
    <script>
    END3
    $tfh.say: qq:to/END2/;
        const Url = 'http://$app-host:$app-port/';
    END2
    $tfh.say: q:to/END/;
        var active_ele;
        function set_initial( start_page ) {
            console.log("Setting Page to : "+start_page);
            document.getElementById('title').innerHTML=start_page;
            active_ele=document.getElementById(start_page);
            active_ele.style.display="inline";
        }
        function change_page( page ) {
            console.log("Setting Page to : "+page);
            document.getElementById('title').innerHTML=page;
            active_ele.style.display="none";
            active_ele = document.getElementById( page );
            active_ele.style.display="inline";
        }
        function db_search( table, id ) {
            var id_uuid = document.getElementById( table+':id:box' ).value;
            console.log("Search table " + table + " for id: " + id_uuid);

            $.ajax({
                url: Url + table + '/' + id_uuid,
                type: "GET",
                success: function(result) {
                    console.log(result);
                    for (let e in result){
                        console.log("Setting " + table + ':' + e + ':box to ' + result[e] );
                        document.getElementById( table + ':' + e + ':box' ).value = result[e];
                    }
                },
                error: function(error) {
                    console.log('Error ${error}')
                }
            })
        }
        function db_save( table ) {
            console.log("Save the fields for table " + table );
            var id_uuid  = document.getElementById( table+':id:box' ).value;
            var data = {};
            var eArray = document.getElementsByClassName( table );
            console.log(eArray);
            for (let ele = 0; ele < eArray.length; ele++ ){
                console.log("setting " + eArray[ele].id );
                var key = eArray[ele].id.split(':')[1]
                console.log("Data Key: " + key + " Value: " + eArray[ele].value);
                data[key] = eArray[ele].value;
            }
            if ( id_uuid == '' ){
                //delete(data[table+':id:box']);
                console.log( data );
                 $.ajax({
                    url: Url + table,
                    type: "POST",
                    data: JSON.stringify(data),
                    contentType:"application/json; charset=utf-8",
                    success: function(result) {
                        console.log(result);
                        for (let e in result){
                            if (e != 'result' ) {
                               console.log("Setting " + table + ':' + e + ':box to ' + result[e] );
                               document.getElementById( table + ':' + e + ':box' ).value = result[e];
                            }
                        }
                    },
                    error: function(error) {
                        console.log('Error ${error}')
                    }
                })
            }
            else{
                console.log( data );
                 $.ajax({
                    url: Url + table,
                    type: "PUT",
                    data: JSON.stringify(data),
                    contentType:"application/json; charset=utf-8",
                    success: function(result) {
                        console.log(result);
                        for (let e in result){
                            if (e != 'result' ) {
                               console.log("Setting " + table + ':' + e + ':box to ' + result[e] );
                               document.getElementById( table + ':' + e + ':box' ).value = result[e];
                            }
                        }
                    },
                    error: function(error) {
                        console.log('Error ${error}')
                    }
                })
            }

        }
        function page_clear( table ) {
            var eArray = document.getElementsByClassName( table );
            console.log(eArray);
            for ( ele in eArray ){
                console.log("Clearing " + eArray[ele].id );
                eArray[ele].value = "";
            }
        }
        function lookup( table, id ) {
            document.getElementById( table+':id:box' ).value = document.getElementById( id ).value;
            change_page( table );
            db_search( table, table+':id:box' );
        }

    </script>
    <style>
       * {
        box-sizing: border-box;
        }   

        body {
            font-family: Arial, Helvetica, sans-serif;
        }

        /* Style the header */
        header {
            background-color: #666;
            padding: 30px;
            text-align: center;
            font-size: 35px;
            color: white;
        }
        nav {
            float: left;
            width: 30%;
            background: #ccc;
            padding: 20px;
        }
        nav ul {
            list-style-type: none;
            padding: 0;
        }
        article {
            float: left;
            padding: 20px;
            width: 70%;
            background-color: #f1f1f1;
        }
        input {
            position: relative;
            left: 2%;
        }
        section::after {
            content: "";
            display: table;
            clear: both;
        }
        @media (max-width: 600px) {
            nav, article {
                width: 100%;
                height: auto;
            }
        }   
    </style>
    <body onload="set_initial('author');">

    <header>
         <h2 id="title"></h2>
    </header>
       <section>
         <nav>
            <ul>
    END
    
    for %tables.keys.sort -> $table {
        next if $table eq 'sqlite_sequence';
        $tfh.say: '         <li><a onclick="change_page(\''~ $table ~ '\')">' ~ $table ~ '</a></li>';
    }
    $tfh.say: q:to/END1/;
            </ul>
         </nav>
         <article>

    END1

    for %tables.kv -> $table, @columns {
        next if $table eq 'sqlite_sequence';
        $tfh.say: qq|       <div id='$table' style='display: none;'>|;
        for @columns -> %col {
            $tfh.say: '           <div id="' ~ $table ~ ':' ~ %col<column_name> ~ '"><span style="display:inline-block;width:180px;">' 
                ~ %col<column_name> ~ ' :</span> <input id=\'' ~ $table ~ ':' ~ %col<column_name> ~ ':box' ~ '\' class="' ~ $table ~ 
                '" size="50" type=text></input>';
            if %col<column_name> ne 'id' and defined(%col<references_table>) {
                $tfh.say: '<button id=lookup style="position: relative; left: 2%;" class="action-button" onclick="lookup(\'' ~ %col<references_table> ~ '\',\'' ~ $table ~ ':' ~ %col<column_name> ~ ':box\')">Lookup</button>';
            }
             $tfh.say: '           </div>';
        }
        $tfh.say: qq:to/END/;
                <button id="clear" class="action-button" onclick="page_clear('{$table}')">Clear</button>
                <button id="search" class="action-button" onclick="db_search('{$table}', 'id')">Search</button>
                <button id="save" class="action-button" onclick="db_save('{$table}')">Save</button>Elapsed Time:<input id='{$table}:elapsed:box' type=text></input>
            </div>
        END
    }
    $tfh.say: q:to/END/;
         </article>
       </section>
     </body>
    </html>
    END
    $tfh.close;
}