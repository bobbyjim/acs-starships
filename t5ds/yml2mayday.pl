use lib '.';
use YAML;
use ACS;
use AcsYAML2Acs;
use strict;
use autodie;
use Data::Dumper;

my $file   = shift || die "SYNOPSIS: $0 >>ACS-YAML_FILE<<\n";

$file =~ s/\.\w+$/.yml/; # make it .yml

my $y          = YAML::LoadFile( $file );
my $hdr        = $y->{ 'header' };
my @components = @{$y->{ 'components' }};

ACS::init( $y );

##########################################################################
#
#  Data Extraction
#
##########################################################################
my $name   = $hdr->{ 'shipname' };
my $qsp    = $hdr->{ 'qsp' };
my $owner  = $hdr->{ 'owner' };
my $tons   = $hdr->{ 'tons' };
my $tl     = $hdr->{ 'tl' };
my $mcr    = $hdr->{ 'totalMCr' };
my ($mission,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;

my ($basicMission) = $qsp =~ /^(\w)/;
my $missionLabel = $hdr->{ 'missionLabel' };
my $comments     = $hdr->{ 'comments' };

my $isMartial   = ACS::isMartial();
my $computer    = ACS::getComputerRating( @components );

my @jInfo       = buildDriveInfo('Jump Drive');
my @mInfo       = buildDriveInfo('Maneuver Drive');
my @pInfo       = buildDriveInfo('PowerPlant');

my $smallCraft  = ACS::getSmallCraft();

my @weaponData  = ACS::grepByType( 'Weapon', @components );
my $primaryTons = ACS::getMainGunTonnage( @weaponData );
my $bayTons     = ACS::getTonnageByMount( "Bay" );
my $lbayTons    = ACS::getTonnageByMount( "LBay" );
my $turretTons  = ACS::getTonnageByMountRx( "T1|T2|T3|T4" );
my $barbetteTons = ACS::getTonnageByMountRx( "B1|B2" );

my $crewExtension = AcsYAML2Acs::parseCrewExtension($comments);

my $isShip      = 1;
   $isShip      = 0 if $tons < 100;

my $fuelTons     = $tons * ($hdr->{ 'jumpFuelPercentage' } + $hdr->{ 'powerFuelPercentage' });
my $howManyJumps = int($hdr->{ 'jf' } / $j);
my $monthsOps    = $hdr->{ 'pf' };

my $staterooms   = 'TBD';
my $lowBerths    = 'TBD';
my $cargo        = $hdr->{ 'totalCargoSpace' };
my $hardpoints   = 'TBD';
my ($armor)      = ACS::grepByType('Armor');
my $armorLabel   = $armor->{ 'label' } || "AV=$tl.";
##########################################################################
#
#  Set up combat profile source data
#
##########################################################################
my @ehex           = ( 0..9, 'A'..'H', 'J'..'N', 'P'..'Z' );

my @out = (
      'index',
      $isShip,
      $name,
      $owner,
      $config,
      $tons,
      $basicMission,
      $mission,
      $missionLabel,
      $isMartial,
      $crewExtension,
      @mInfo,
      @jInfo,
      @pInfo,
      int($fuelTons+0.5),
      $howManyJumps,
      $computer,
      $staterooms,
      $lowBerths,
      $cargo,
      $primaryTons,
      $lbayTons,
      $bayTons,
      $barbetteTons,
      $turretTons,
      $armorLabel,
      $mcr
);

print join( ',', @out ), "\n";

print STDERR sprintf "%-12s  %-18s  %-18s  %4d  $mcr\n", 
   $owner,
	$name,
	$missionLabel,
	$tons;

sub buildDriveInfo
{
   my $driveType = shift;
   my $drive  = ACS::grepCategory($driveType);
   my $letter = $drive->{ 'code' };
   my $rating = $drive->{ 'rating' }; 
   return ($letter, $rating);
}