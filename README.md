# mmt

mmt -- Master Maintenance Tool perl module.

<pre>
tree -f |perl -alne '@x=split /\s+/,`wc -l $F[-1] 2>/dev/null`;$l=sprintf("%5d %s",$x[0],$_);$l=~ s/ 0 /   /;$l=~ s{\..*/}{};print $l'
      .
    3 ├── README.md
      └── toolmmt
          ├── lib
          │   └── Tool
          │       ├── Model
          │       │   ├── Webdb
   29     │       │   │   └── constant.pm
  210     │       │   └── Webdb.pm
    7     │       ├── Model.pm
          │       ├── mmt
   35     │       │   ├── Commodity.pm
   13     │       │   ├── Example.pm
  769     │       │   ├── Mmt.pm
   19     │       │   └── Usertbl.pm
   28     │       └── mmt.pm
          ├── log
          ├── public
          │   ├── css
  121     │   │   └── default.css
   11     │   ├── index.html
          │   └── js
          ├── script
   11     │   └── toolmmt
          ├── t
    9     │   └── basic.t
          └── templates
              ├── example
    7         │   └── welcome.html.ep
              ├── layouts
   34         │   ├── default.html.ep
   37         │   └── defsubwin.html.ep
              └── mmt
   36             ├── datalist.html.ep
    9             ├── desc.html.ep
   53             ├── mainform.html.ep
   34             └── subwin.html.ep
      
      16 directories, 20 files
</pre>
