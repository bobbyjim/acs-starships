use YAML;
use strict;

my @ep2letter = qw/A B C D E F G H J K L M N P Q R S T U V W X Y Z/;

my %missionLabel = (
   'A'    =>  'Trader' ,
   'A2'   =>  'Far Trader' ,
   'AF'   =>  'Fast Trader' ,
   'AG'   =>  'Gunned Trader' ,
   'AL'   =>  'Exploratory Trader' ,
   'B'    =>  'Monitor' ,
   'C'    =>  'Cruiser' ,
   'CB'   =>  'Battle Cruiser' ,
   'CBY'  =>  'Battle Rider' ,
   'CF'   =>  'Frontier Cruiser' ,
   'CP'   =>  'Mercenary Cruiser' ,
   'D'    =>  'Defender' ,
   'DS'   =>  'System Defense' ,
   'DL'   =>  'Wilderness Defender' ,
   'E'    =>  'Escort' ,
   'EB'   =>  'Corvette' ,
   'EC'   =>  'Close Escort' ,
   'EF'   =>  'Fast Escort'  ,
   'EG'   =>  'Gunned Escort' ,
   'EM'   =>  'Mercenary Escort' ,
   'EN'   =>  'Naval Escort' ,
   'EP'   =>  'Patrol Corvette' ,
   'EY'   =>  'Rider Escort' ,
   'F'    =>  'Freighter' ,
   'FB'   =>  'Bulk Freighter' ,
   'FF'   =>  'Frontier Freighter' ,
   'FK'   =>  'Subsidized Freighter', 
   'FS'   =>  'System Freighter' ,
   'G'    =>  'Frigate' ,
   'GBS'  =>  'Gunboat' ,
   'CG'   =>  'Carrier Frigate' ,
   'MG'   =>  'Mercenary Frigate' ,
   'PG'   =>  'Patrol Frigate' ,
   'H'   =>  'Ortillery' ,
   'J'   =>  'Prospector' ,
   'JF'   =>  'Frontier Prospector' ,
   'JJ'   =>  'Survey Prospector' ,
   'K'    =>  'Touring Ship' ,
   'KA'   =>  'Expedition' ,
   'KF'   =>  'Far Expedition' ,
   'KJ'   =>  'Survey Expedition' ,
   'KS'   =>  'Safari Ship' ,
   'L'    =>  'Lab Ship' ,
   'LC'   =>  'Communications Lab' ,
   'LN'   =>  'Naval Lab Ship' ,
   'LS'   =>  'System Lab Ship' ,
   'M'    =>  'Liner' ,
   'MF'   =>  'Fast Liner' ,
   'MK'   =>  'Subsidized Liner' ,
   'ML'   =>  'Long Liner' ,
   'MS'   =>  'System Liner' ,
   'N'    =>  'Surveyor' ,
   'NC'   =>  'Communications Beagle' ,
   'NF'   =>  'Frontier Beagle' ,
   'NJ'   =>  'Survey Beagle' ,
   'NP'   =>  'Medical Ship' ,
   'NR'   =>  'Search/Rescue Ship' ,
   'P'    =>  'Corsair' ,
   'PQ'   =>  'Privateer' ,
   'PN'   =>  'Marauder' ,
   'PL'   =>  'Picket' ,
   'PF'   =>  'Fast Patrol' ,
   'PP'   =>  'Patrol' ,
   'PR'   =>  'Search and Rescue' ,
   'QA'   =>  'Lifeboat' ,
   'QB'   =>  "Ship's Boat" ,
   'QC'   =>  'Cutter' ,
   'QG'   =>  'Gig' ,
   'QN'   =>  'Pinnace' ,
   'QS'   =>  'Shuttle' ,
   'R'    =>  'Merchant' ,
   'RC'   =>  'Merchant Cruiser'      ,
   'RF'   =>  'Frontier Merchant',
   'RK'   =>  'Subsidized Merchant' ,
   'RL'   =>  'Exploratory Merchant' ,
   'RQ'   =>  'Raider' ,
   'RB'   =>  'Battle Raider' ,
   'RM'   =>  'Mercenary Raider' ,
   'S'    =>  'Scout/Courier' ,
   'SL'   =>  'Long Range Courier' ,
   'SR'   =>  'Recon Scout' ,
   'SC'   =>  'Courier' ,
   'SD'   =>  'Sentinel' ,
   'T'    =>  'Transport' ,
   'TB'   =>  'Assault' ,
   'TC'   =>  'Tender' ,
   'TH'   =>  'Tanker' ,
   'TL'   =>  'Clan Transport' ,
   'TM'   =>  'Tug' ,
   'TN'   =>  'Naval Tender' ,
   'TV'   =>  'Fighter Carrier' ,
   'TY'   =>  'Rider Carrier' ,
   'U'    =>  'Packet' ,
   'UF'   =>  'Fast Packet' ,
   'UG'   =>  'Gunned Packet' ,
   'UL'   =>  'Long Packet' ,
   'UM'   =>  'Military Packet' ,
   'UN'   =>  'Naval Packet' ,
   'V'    =>  'Destroyer' ,
   'VE'   =>  'Destroyer Escort' ,
   'W'    =>  'Barge' ,
   'WH'   =>  'Fuel Container' ,
   'WT'   =>  'Cargo Container' ,
   'X'    =>  'Express Courier' ,
   'Y'    =>  'Yacht' ,
   'YF'   =>  'Fast Yacht' ,
   'YL'   =>  'Long Yacht' ,
   'YS'   =>  'Luxury Yacht' ,
   'Z'    =>  'Unclassified' ,
);

my $shipclass = shift || synopsis(); 
my $qsp       = shift || synopsis();
my $tl        = shift || 10;

$/ = undef; # slurp mode
my $template = <DATA>;
my $ship = YAML::Load($template);

#print $ship->{'header'}->{'format'}, "\n";

if ($qsp)
{
   $ship->{header}->{shipname} = $shipclass;
   $ship->{header}->{qsp}    = $qsp;

   my ($mission, $siz, $cfg, $m, $j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;
   $ship->{header}->{mission} = $mission;
   $ship->{header}->{missionLabel} = $missionLabel{ $mission };
   $ship->{header}->{tons}    = siz2tons($siz);
   $ship->{header}->{config}  = $cfg;
   $ship->{header}->{m}       = $m; # drive2letter($m, $ship->{header}->{tons});
   $ship->{header}->{j}       = $j; # drive2letter($j, $ship->{header}->{tons});
   $ship->{header}->{tl}      = $tl;

   addJumpDrive($j, $ship->{header}->{tons}, $tl);
   addManeuverDrive($m, $ship->{header}->{tons}, $tl);
   addPowerPlant($m > $j? $m : $j, $ship->{header}->{tons}, $tl);
}

print Dump $ship;

sub synopsis
{
    die "SYNOPSIS: $0 shipclass QSP [TL]\n";
}

sub siz2tons
{
    my $tons = ord(shift) - 64; # 65 - 90
    $tons-- if $tons > 72; # I
    $tons-- if $tons > 78; # O
    return $tons * 100;
}

sub drive2letter
{
    my $rating   = shift;
    my $shiptons = shift;

    my $index = int($rating * $shiptons / 200) - 1;

    return $ep2letter[ $index   ] if $index < 24;
    return $ep2letter[ $index/2 ] . '2';
}

sub jump2Vol
{
    my $rating = shift;
    my $hull   = shift;
    return 5 + 5 * int($rating * $hull/200);
}

sub maneuver2Vol
{
    my $rating = shift;
    my $hull   = shift;
    my $ep     = int($rating * $hull/200);
    return 2 if $ep == 1;
    return 2 * $ep - 1;
}

sub power2Vol
{
    my $rating = shift;
    my $hull   = shift;
    return 1 + 3 * int($rating * $hull/200);
}

sub addJumpDrive
{
    my $rating = shift;
    my $tons   = shift;
    my $tl     = shift;
    my $letter = drive2letter( $rating, $tons );
    my $vol    = jump2Vol( $rating, $tons );
    my $mcr    = $vol;

    push @{$ship->{components}}, 
    {   
       type           => 'Drive', 
       category       => 'Jump Drive', 
       name           => 'Jump Drive',
       label          => "Jump Drive-$rating ($letter)",
       rating         => $rating, 
       code           => $letter,
       tons           => $vol, 
       totalTons      => $vol,
       jumpFuelUsage  => 0.1,
       basetl         => $tl,
       tl             => $tl,
       target         => $tl,
       mcr            => $mcr,
       totalMCr       => $mcr,
       howMany        => 1,
       autoAdjust     => 1,
       CP             => 1,
       notes          => 'J ' . $rating
    };
}

sub addManeuverDrive
{
    my $rating = shift;
    my $tons   = shift;
    my $tl     = shift;
    my $letter = drive2letter( $rating, $tons );
    my $vol    = maneuver2Vol( $rating, $tons );
    my $mcr    = 2 * $vol;
    push @{$ship->{components}}, 
    {
       type           => 'Drive', 
       category       => 'Maneuver Drive', 
       name           => 'Maneuver Drive', 
       label          => "Maneuver Drive-$rating ($letter)",
       rating         => $rating, 
       code           => $letter,
       tons           => $vol, 
       totalTons      => $vol,
       basetl         => $tl,
       tl             => $tl,
       target         => $tl,
       mcr            => $mcr,
       totalMCr       => $mcr,
       howMany        => 1,
       autoAdjust     => 1,
       CP             => 1,
       notes          => 'M ' . $rating
    };
}

sub addPowerPlant
{
    my $rating = shift;
    my $tons   = shift;
    my $tl     = shift;
    my $letter = drive2letter( $rating, $tons );
    my $vol    = power2Vol( $rating, $tons );
    my $mcr    = $vol;
    push @{$ship->{components}}, 
    {
       type           => 'Drive', 
       category       => 'PowerPlant', 
       name           => 'PowerPlant', 
       label          => "PowerPlant-$rating ($letter)",
       rating         => $rating, 
       code           => $letter,
       tons           => $vol, 
       totalTons      => $vol,
       powerFuelUsage => 0.01,
       basetl         => $tl,
       tl             => $tl,
       target         => $tl,
       mcr            => $mcr,
       totalMCr       => $mcr,
       howMany        => 1,
       autoAdjust     => 1,
       CP             => 1,
       notes          => 'P ' . $rating
    };
}

__DATA__
--- 
header:
   format: 'T5-ACS-1'
   tons: 200
   tl: 10
   mission: 'A'
   config: 'S'
   spaciousness: 2
   shifts: 1

components:
   - {type: 'Hull', category: 'Hull', label: 'Streamlined hull', eff: 1, name: 'Hull', config: 'Streamlined', code: 'S', mcr: 14, tons: 200, mult: 1}
   - 
      type: 'Payload'
      category: 'Cargo'
      label: 'Cargo Hold Basic'
      mcr: 0
      eff: 1
      tons: '20'
      notes: ''
   - 
      mount: 'Surf'
      type: 'Sensor'
      range: 'AR'
      totalTons: 0
      howMany: 1
      totalMCr: 6
      tl: 10
      label: 'AR Surf Basic C-R-T'
      mod: 0
      q: 0
      target: 10
      r: 0
      eff: 1
      s: 0
      tons: 0
      b: 0
      notes: ''
      category: 'AR Surf Basic C-R-T'
      basetl: 10
      e: 0
      mcr: 6
      name: 'Basic C-R-T'
      CP: 1
      config: 'Sensor'

