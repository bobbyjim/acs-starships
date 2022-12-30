use strict;

my %types = ();

foreach (`grep "type:" *.yml`)
{
   /type: (.*),?\n?/;
   $types{$1}++;
}

print "TYPES:\n";
foreach (sort keys %types)
{
   printf "%-5d: $_\n", $types{$_};
}
print "\n\n";

my %cats = ();

foreach (`grep "category:" *.yml`)
{
   my ($thing) = /category: (.*),?\n?/;
   my $mount = '';

   $thing = "Armor of some kind" if $thing =~ /AV=\d/;
   $thing =~ s/'//g;
   $thing = $1 if /(Model.\d)/;
   $thing = "Model/$1" if /Computer M(\d)/;
   $thing =~ s/(Vd|Or|Fo|DS|SR|LR|G|L|D) //;
   ($mount, $thing) = ($1, $3) if $thing =~ /(T1|T2|T3|T4|M|B|Surf|Bay|Ant|Ext|B1|B2)(de)? (.*)/;

   next if $thing =~ /Space/;
   next if $thing eq 'Empty' || $thing eq 'Computer';

   $cats{$thing}++;
}

print "CATEGORIES:\n";
my $id = 0;
foreach (sort keys %cats)
{
   printf "  %24s => $id,\n", $_;
   ++$id;
}
print "\n\n";

print scalar keys %cats, " entries\n";
