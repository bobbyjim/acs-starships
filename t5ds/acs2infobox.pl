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
    'L' => 'Lifting Body'
);

my $file   = shift || die "SYNOPSIS: $0 acs file\n";

$file .= '.'   unless $file =~ /\.$/;
$file .= 'acs.txt' unless $file =~ /acs.txt$/;

my $y      = YAML::LoadFile( $file );
my $name   = $y->{ 'Name' };
my $qsp    = $y->{ 'QSP' };
my ($tdes,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;
my $cfg    = $cfg{ $config };
my $type   = $y->{ 'Mission' };
my $size   = $y->{ 'Tons' };
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
my $hp     = $y->{ 'Hardpoints' } || int($size/100);
my $cx     = $y->{ 'Cx' };
my $vx     = $y->{ 'Vx' } || 'None';

print<<EODUMP;
 |name         = $name class $type
 |image        = 
 |caption      = 
 |tdes         = $tdes
 |type         = $type
 | 
 |size-cat    = ACS
 |size        = $size
 |hull        = $cfg Hull
 |aerodynam   = $stream Hull
 |TL          = $tl
 | 
 |model       = $comp
 |jump        = $j
 |g           = $m
 |fuelTreatment = $fuelTreatment
 | 
 |hp          = $hp
 |weapons     =
 |screens     = 
 | 
 |staterooms  = 
 |bunks       = 
 |seats       = 
 |lowberths   = $low
 | 
 |crew        = $cx
 |officers    = 
 |enlisted    = 
 |pilots      = 
 |marines     = 
 |frozenwatch = 
 |passengers  = 
 |steerage    = 
 |Lpass       = $low
 | 
 |cargo       = $cargo
 |fuel        = $fuel
 |craft       = $vx
 |
 |construction = 
 |origin       = Third Imperium
 |manufacturer = $builder
 |IOC          = Unknown
 |EOS          = Still in active service.
 |
 |cost         = $mcr
 |architect    = $arch
 | 
 |QSP         = $qsp
 |USP         =
 |
 |blueprint   = 
 |illustration =  
 | 
 |alsosee     = $type
 |canon       = Yes
 |designer    = 
 |designSystem = Traveller5
 |era         = 1105
 |ref         = {{Ludography ref|name= Starships|version= Classic Traveller |page= 19}}
 |footnote    = [[Starship]]s are designed with the [[Classic Traveller]] format, using [[Traveller 5]].
EODUMP
