# MyTNS
manage aliases in the file tnsnames.ora

# Name
MyTNS.pm

# SYNOPSYS
```
use MyTNS;
my $tns=MyTNS->new("tnsnames.ora");

if ($tns->check()) { print "the file is not valid !\n\n"; }

if ($tns->exists("HP6")) { print "alias HP6 exists\n"; } else { print "alias HP6 does not exist\n"; }

$tns->add("string"=>"
  hp3=(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630))))
");

$tns->remove("hp3");

$tns->commit;
```

# DESCRIPTION
The perl module MyTNS manages aliases in the file tnsnames.ora.
It can check the syntax of all entries in the file, says if an alias is declared, add aliases, remove aliases.

# USAGE
First, let's create an MyTNS object :

```
#!/usr/bin/perl -w

use MyTNS;
use strict;

my $tns=MyTNS->new("tnsnames.ora");
```
Then let's see if the content on the file tnsnames.ora is syntactically correct:
```
my $rc=$tns->check();
if ($rc) {
  print "the file 'tnsnames.ora' is not valid\n\n";
  exit($rc);
}
print "the file 'tnsnames.ora' is valid\n\n";
```

Lets's see the content of the tnsnames.ora :
```
$ cat tnsnames.ora

# test file

sample1,sample2.world,sample3=
 (DESCRIPTION=
   (SOURCE_ROUTE=yes)
   (ADDRESS=(PROTOCOL=tcp)(HOST=host1)(PORT=1630))    # hop 1
   (ADDRESS_LIST=
     (FAILOVER=on)
     (LOAD_BALANCE=off)                                # hop 2
     (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
     (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630)))
   (ADDRESS=(PROTOCOL=tcp)(HOST=host3)(PORT=1521))    # hop 3
   (CONNECT_DATA=(SERVICE_NAME=Sales.us.example.com)))

hp6=(DESCRIPTION=(ADDRESS_LIST= 
  (FAILOVER=ON) (LOAD_BALANCE=off)
  (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
  (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630)) ) )
```

We can test the existence of some aliases :
```
foreach my $alias ("sample1", "sample2", "sample3", "hp6", "hp3", "pm12") {
  if ($tns->exists($alias)) { print "$alias exists\n"; } else { print "$alias does not exist\n"; }
}

sample1 exists
sample2 does not exist
sample3 exists
hp6 exists
hp3 does not exist
pm12 does not exist
```

Let's remove the 'hp6' alias :
```
$tns->remove("HP6"); # case insensitive
```

... and add the 'hp3' alias with it's description :
```
$tns->add("string"=>"hp3=(DESCRIPTION=(ADDRESS_LIST=
  (FAILOVER=ON) (LOAD_BALANCE=off)
  (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
  (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630)) ) )");
```

In order to write down these changes in the file tnsnames.ora, let's commit :
```
$tns->commit;
```
