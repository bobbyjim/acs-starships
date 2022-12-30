use YAML;
use strict;
use autodie;

my %cfg = (
    'C' => 'Cluster',
    'B' => 'Braced',
    'P' => 'Planetoid',
    'U' => 'Unstreamlined',
    'S' => 'Streamlined',
    'A' => 'Airframe',
    'L' => 'Lift Body'
);

foreach my $file (<*.acs.txt>)
{
   my $y      = YAML::LoadFile( $file );
   my $name   = $y->{ 'Name' };
   my $qsp    = $y->{ 'QSP' };
   my ($tdes,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;
   my $cfg    = $cfg{ $config };
   my $type   = $y->{ 'Mission' };
   my $tons   = $y->{ 'Tons' };
   my $stream = ($config =~ /[SAL]/)? 'Streamlined' : 'Unstreamlined';
   my $tl     = $y->{ 'TL' };
   my $comp   = $y->{ 'Computer' };
   my $builder = $y->{ 'Builder' } || 'Various';
   my $arch   = $y->{ 'Architect' };
   my $mcr    = $y->{ 'MCr' };
   my $cargo  = $y->{ 'Cargo' };
   my $fuel   = $y->{ 'Fuel' };
   my $fuelTreatment = $y->{ 'Fuel treatment' };
   my $low    = $y->{ 'Low berths' };
   my $hp     = $y->{ 'Hardpoints' } || int($tons/100);
   my $cx     = $y->{ 'Cx' };
   my $vx     = $y->{ 'Vx' } || 'None';
#   my $mission = $y->{ 'Mission' };

   print "$name $qsp"
   print maybeTrader($y)? 'Merchant'
   : 'Not a merchant';
}

sub maybeTrader
{
    my $y = shift;
    my $qsp    = $y->{ 'QSP' };
    my ($tdes,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;
    my $cargo = $y->{ 'Cargo' };
    my $pass  = $y->{ 'Passengers' };
    my $cargoToPax = $cargo/$pax;

    return 1 if ($cargo > 49) && ($m == 1);
    return 0;
}

sub maybeLiner
{
    my $y = shift;
    my $qsp    = $y->{ 'QSP' };
    my ($tdes,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;
    my $cargo = $y->{ 'Cargo' };
    my $pass  = $y->{ 'Passengers' };
    my $cargoToPax = $cargo/$pax;

    return 1 if ($jump > 1) && ($cargoToPax < 7);
    return 0;
}