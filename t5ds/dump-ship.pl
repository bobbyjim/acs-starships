use strict;
use autodie;

my $file = shift or die "SYNOPSIS: $0 filename\n";

open my $fp, '<:raw', $file;
read $fp, my $buffer, 256;   # max read 256b (ship file should be only 160b)
close $fp;

my ($name, $mission, $siz, $cfg, $m, $j, $h, $model, $landers, $comfort, $demand, $av, $cargop, $fuelp, $owner)
   = unpack "A31 x A2 C A CCCC ACCC CC A A", $buffer;

my $fuel = $fuelp * $siz;
my $cargo = $cargop * $siz;

$siz *= 100;
$comfort -= 5;
$demand -= 5;

$owner = 'Aslan'    if $owner eq 'A';
$owner = 'Droyne'   if $owner eq 'D';
$owner = 'Humbolt'  if $owner eq 'H';
$owner = 'Imperial' if $owner eq 'I';
$owner = 'Kursae'   if $owner eq 'K';
$owner = 'Valtra'   if $owner eq 'L';
$owner = 'Al Morai' if $owner eq 'M';
$owner = 'Republic' if $owner eq 'R';
$owner = 'Sword Worlds' if $owner eq 'S';
$owner = 'Vargr'    if $owner eq 'V';
$owner = 'Zhodani'  if $owner eq 'Z';

$cfg = 'Cluster'       if $cfg eq 'C';
$cfg = 'Braced'        if $cfg eq 'B';
$cfg = 'Planetoid'     if $cfg eq 'P';
$cfg = 'Unstreamlined' if $cfg eq 'U';
$cfg = 'Streamlined'   if $cfg eq 'S';
$cfg = 'Airframe'      if $cfg eq 'A';
$cfg = 'Lift Body'     if $cfg eq 'L';

=pod
   print OUT pack 'A31x', $hdr{classname};
   print OUT pack 'A2',   $hdr{mission};
   print OUT pack 'C',    $hdr{siz};
   print OUT pack 'A',    $hdr{cfg};
   print OUT pack 'CCCC', $hdr{mnv}, $hdr{jmp}, $hdr{hop};
   print OUT pack 'ACCC', $hdr{landers}, $hdr{comfort}, $hdr{demand}, $hdr{av};
   print OUT pack 'CC',   $hdr{cargop}, $hdr{fuelp};
   print OUT pack 'A',    $hdr{owner};
   print OUT pack 'A',    '-';    # placeholder
=cut

print<<EODAT;
    Name: $name
 Mission: $mission
    Size: $siz t
     Cfg: $cfg
Maneuver: $m
    Jump: $j
     Hop: $h
Computer: Model/$model
 Landers: $landers
 Comfort: $comfort
  Demand: $demand
      AV: $av
   Cargo: $cargo t
    Fuel: $fuel t
   Owner: $owner
EODAT
