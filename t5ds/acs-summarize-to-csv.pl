use YAML;
use strict;

my $pattern = shift @ARGV;

my @letter = qw/A B C D E F G H J K L M  N  P  Q  R  S  T  U  V  W  X  Y  Z  N2
                N2 N2 P2 P2 Q2 Q2 R2 R2 S2 S2 T2 T2 U2 U2 V2 V2 W2 W2 X2 X2 Y2 Y2 Z2 Z2/;

my %weaponCode = (
	'Particle Accelerator' 	=> 'A',
   'CommCaster'      => 'C',
   'DataCaster'      => 'D',
   'Fusion Gun'      => 'F',
   'Meson Gun'       => 'G',
   'Mining Laser'    => 'J',
	'Pulse Laser'		=> 'K',
	'Beam Laser'		=> 'L',
	'Missile'		   => 'M',
   'KK Missile'      => 'N',
   'Plasma Gun'      => 'P',
   'Ortillery'       => 'Q',
   'Rail Gun'        => 'R',
	'Sandcaster'		=> 'S',
   'Tractor/Pressor' => 'U',
   'Salvo Rack'      => 'V',
   'AM Missile'      => 'X',
	'Empty'			   => '',
	'Hybrid L-S-M'		=> 'L S M',
);

my %configCode = (
	C => 'Cluster hull.',
	B => 'Braced hull.',
	P => 'Planetoid hull.',
	U => 'Unstreamlined hull.',
	S => 'Streamlined hull.',
	A => 'Airframe hull.',
	L => 'Lift-Body hull.',
);

my %vehicleCode = (
	AdvMWQF		=> 'F', # fighter
	AltHGC		=> 'g', # GCarrier
	ELPV		=> 'R', # air/raft
	FPGPH		=> 'H', # speeder
	HMAMFQF		=> 'F', # fighter
	LMAQB		=> 'G', # gig
	LMQS		=> 'S', # shuttle
	LMUQP		=> 'A', # lifeboat / pod
	MCQS		=> 'S', # cargo shuttle
	MFQB		=> 'B', # boat
	MFQN		=> 'N', # pinnace
	MQC		=> 'C', # cutter
	MQF		=> 'F', # fighter
	MSQB		=> 'B', # slow boat
	MSQL		=> 'L', # launch
	MSQN		=> 'P', # slow pinnace
	VlMLiQB		=> 'B', # boat
);

$/ = undef;
my %catalog;
my %catalogStructure;
my $ships = 0;
foreach my $file (<$pattern*.yml>)
{
   my $file_age = -M $file;
   my $yaml = YAML::LoadFile( $file );

   my ($owner) = $file =~ /^(.*?)[\s-]/;
   my ($allegiance) = $owner =~ /^(..)/;

   if ($owner eq 'ACS')
   {
      print "Please FIX owner: $file\n";
      next;
   }

   my $hdr     = $yaml->{ header };
   my $qsp      = $hdr->{ qsp };
   my $vol      = $hdr->{ tons };
   $allegiance  = $hdr->{ allegiance } if $hdr->{ allegiance };

   $allegiance  =~ s/(....).*$/$1/; # shorten to 4 per allegiance codes

   next if $vol > 5000;  #  too large


   my $hp       = int($vol/100);
   my $name     = $hdr->{ shipname };
   my $tl       = $hdr->{ tl };
   my $free     = $hdr->{ tonsFree };
   my ($mission, $hull, $config, $maneuver, $jump) = $hdr->{ qsp } =~ /^(.*)-(.\d?)(.)(.)(.)/;
   my $missionLabel = $hdr->{ missionLabel };
   my $pp       = '';
   my ($mn,$jn) = ($1,$2) if $qsp =~ /(.)(.)$/;
   my $fuel     = 0;
   my $duration = '';
   my $cost     = $hdr->{ totalMCr };
   my $comp     = '';
   my $crew     = $hdr->{ crew };
   my $pass     = $hdr->{ passengers };
   my $stewards  = $pass / 8;
   my $lb       = 0;
   my $notes    = '';
   my $av       = $tl;

   my $bridge   = 'Standard';
      $bridge   = 'Spacious' if $hdr->{ spaciousness } > 1.5; # typical
      $bridge   = 'Cramped'  if $hdr->{ spaciousness } < 1;

   my $spaciousness = $hdr->{ spaciousness };

   my $sr       = 0;
   my $cargo    = $hdr->{ 'totalCargoSpace' };
   my @fuel = ();
   my @hull = ();
   my $landingLegs = ' ';
   my $hullFeature = ' ';

   my @comp = @{$yaml->{ components }};
   my $engineers = 0;

   my %vehicles = ();
   my $wpn = '';
   my $wpnTons = 0;

   foreach my $component (@comp)
   {
      if ( $component->{ 'type' } eq 'Drive' )
      {
         $engineers += $component->{ 'totalTons' } / 35; # $component->{ 'CP' };
      }
      elsif ($component->{ 'type' } eq 'Vehicle' && $component->{ 'code' } )
      {
         my $code = $vehicleCode{ $component->{ 'code' } };
         $vehicles{ $code }++;
      }
      elsif ($component->{ 'type' } eq 'Armor' )
      {
         ($av) = $component->{ 'category' } =~ /AV=(\d+)/ if $component->{ 'category' } =~ /AV=[^0]/;
      }
      elsif ($component->{ 'type' } eq 'Weapon' && $component->{ 'tons' } > $wpnTons)
      {
         $wpnTons = $component->{ 'tons' };
         ($wpn)   = $component->{ 'mount' } =~ /^(..)/; # first 2 chars
         $wpn    .= $weaponCode{ $component->{ 'name' } };
      }

      if ( $component->{ 'category' } eq 'PowerPlant' )
      {
         $pp = $component->{ 'rating' };
      }
      elsif ( $component->{ 'category' } =~ /(Powerplant|Jump) Fuel/ )
      {
         $fuel += $component->{ 'totalTons' };
         if ( $component->{ 'category' } eq 'Powerplant Fuel' )
         {
            $duration = $component->{ 'notes' };
         }
      }
      elsif ( $component->{ 'name' } eq 'Computer' )
      {
         $comp = $component->{ 'mount' };
      }
      elsif ( $component->{ 'label' } eq 'Low Berth' )
      {
         $lb = $component->{ 'howMany' };
      }
      elsif ( $component->{ 'label' } =~ /Stateroom/ )
      {
         $sr += $component->{ 'howMany' };
      }
      elsif ( $component->{ 'label' } =~ /Fuel Scoops/ )
      {
         push @fuel, 'scoops';
      }
      elsif ( $component->{ 'label' } =~ /Fuel Intakes/ )
      {
         push @fuel, 'intakes';
      }
      elsif ( $component->{ 'label' } =~ /Fuel Bins/ )
      {
         push @fuel, 'bins';
      }
      elsif ( $component->{ 'label' } =~ /Flotation|Submersible/ )
      {
         $hullFeature = $component->{ 'code' };
         push @hull, $component->{ 'label' };
      }
      elsif ( $component->{ 'label' } =~ /Landing legs/ )
      {
         $landingLegs = $component->{ 'code' }; # 1;
      }
   }

   $comp =~ s/Model\///;

   # 
   #  Drive letters run from 0 (A) to 23 (Z).
   #  Multiply drive rating x hull volume / 200 to get the drive letter.
   #
   my $m1 = int(0.5 + $mn * $vol / 200);
   my $j1 = int(0.5 + $jn * $vol / 200);
   my $p1 = int(0.5 + $pp * $vol / 200);

   my $mletter = $letter[ $m1 ];
   my $jletter = $letter[ $j1 ];
   my $pletter = $letter[ $p1 ];

   push @hull, 'Landing skids (tarmac only)' unless $landingLegs eq 'K'; # legs are the default

   my $fuelStuff = '';
   $fuelStuff = 'Fuel ' . join(', ', sort @fuel)  if @fuel;
   push @hull, $fuelStuff if $fuelStuff;
   my $hull = join ', ', sort @hull;
   $hull .= '.' if $hull =~ /\w/;
   $hull = '' unless $hull =~ /\w/;

   $ships++;

   my @weaponData      = grepByType( 'Weapon',    @comp );
   my @defenseData     = grepByType( 'Defense',   @comp );

   #
   #  Calculate vehicle numbers
   #
   my $vehicles = '';
   foreach my $code (sort keys %vehicles)
   { 
      $vehicles .= $code . $vehicles{$code} . ',';
   }
   chop $vehicles;

   my $shipKey = $qsp . $name . $owner;
   $fuel = int $fuel;
   $cargo = int $cargo;

   $catalogStructure{ $shipKey } = {
        owner		=> $owner,
 	qsp		=> $qsp,
	name 		=> $name,
	mission 	=> "$missionLabel", #  (type $mission)",
   fileAge  => int($file_age),
	tons		=> $vol,
	configCode	=> $config,
   config		=> $configCode{ $config },
	mdrive		=> $mletter,      # "M-Drive ${mn}G  "  . countDownLetters($mletter),
	jdrive		=> $jletter,      # "J-Drive J${jn}  "  . countDownLetters($jletter),
	pplant		=> $pletter, # "Power Plant     "  . countDownLetters($pletter),
	fuel		   => $fuel,    # "Fuel $fuel      "  . countDownNumbers($fuel),
	hold		   => $cargo,   # "Hold $cargo     "  . countDownNumbers($cargo),
	bridge		=> $bridge,
   spaciousness => $spaciousness,
	computer	=> $comp,
   crew        => $crew,
	passengers  => $pass,
	lowBerths	=> $lb,
	engineers	=> int $engineers,
	stewards	=> int $stewards,
	mcr		=> $cost,
        vehicles	=> $vehicles,
   };

   my $enum = 1;
   foreach my $h (@weaponData, @defenseData)
   {
      my ($mount,$num) = $h->{ 'mount' } =~ /(.)(.)/;
      $num |= 1;
      my $code = $weaponCode{$h->{ 'name' }} || $h->{ 'name' };

      if (length($code) == 1)
      {
        $code .= " $code" if $num == 2;
        $code .= " $code $code" if $num == 3;
      }

      for (1..$h->{ 'howMany' })
      {
         $catalogStructure{ $shipKey }->{ 'h' . $enum } = "${mount}$num $code";
         ++$enum;
      }
   }

   my $qsp2 = $qsp;

#   my $middle = sprintf "%2d/%-2d | %3d | %3s", $pass, $lb, $av, $wpn;

#   $middle = sprintf( "%3d %3s", $av, $wpn ) if $mission =~ /^[CDEHGPSTV]/ || $pass <= 1; # martial
#   $qsp2 =~ s/^(\w)\w\w?/$1/;

#   my $detail = '';
#   $detail .= '+' if int($spaciousness) > 0;
#   $detail .= '-' if int($spaciousness) == 0;
   my $detail .= int($spaciousness) . ' ' . $landingLegs . $hullFeature;

#   print STDERR sprintf "%-8s | %-4s | %s | %-12s%s $name\n", 
#		$qsp2, 
#                $detail,
#		$middle,
#		$vehicles,
#		$allegiance;

   # Vx: $vehicles
   print STDERR sprintf "%2s %-8s $name\n", 
		$allegiance,
		$qsp2;

}

# removed: Mission, Age, Tons, Hull Config, M, J, P, 
print<<EOHEADER;
Owner, QSP, Name, Fuel, Hold, Br., CPU, Crew, Pass, Low, Eng, Stw, MCr, H1, H2, H3, H4, H5, H6, H7, H8, H9, H10, H11, H12, H13, H14, H15, H16
EOHEADER

foreach my $key (sort keys %catalogStructure)
{
   my $rec = $catalogStructure{ $key };
   # removed: 'mission','fileAge', 'tons','config','mdrive','jdrive','pplant',
   foreach my $field ('owner','qsp','name','fuel','hold','spaciousness','computer','crew','passengers','lowBerths','engineers','stewards','mcr','h1','h2','h3','h4','h5','h6','h7','h8','h9','h10','h11','h12','h13','h14','h15','h16')
   {
      print $rec->{$field}, ',';
   }
   print "\n";
}

sub countDownLetters
{
   my $start = shift;
   my @stack = ();
   foreach my $letter (@letter)
   {
      unshift @stack, $letter;
      last if $letter eq $start;
   }
   return join ' ', @stack;
}

sub countDownNumbers
{
   my $start = shift;
   my @stack = ();
   for (1..100)
   {
      my $val = $_ * 10;
      unshift @stack, $val;
      last if $val + 10 >= $start;
   }
   return join ' ', @stack;
}

sub grepByType
{
   my $type = shift;
   my @list = @_;

   return () unless @list;

   my @out = ();
   foreach my $item (@list)
   {
      push @out, $item if $item->{ type } eq $type;
   }
   return @out;
}

