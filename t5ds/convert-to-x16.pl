use strict;
use YAML;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;

=pod
********************************************************************************

   The goal is to encode a ship by its characteristics and component list.

   Components are identified by a unique 8-bit TYPE(:3)+DEVICE(:5) identifier.

   Most of the components are distinctly recognizable by the 'category' field,
   with the exception of 'fittings'.

********************************************************************************
=cut

my $pattern = shift @ARGV;

$/ = undef;
my %catalog;
my @list;
my $ships = 0;
my %deviceMap;
my $componentIDs = getComponentMap();
my $ownerMap = mapOwner();

foreach my $file (<$pattern*.yml>)
{
   #print STDERR "$file\n";
   my $yaml = YAML::LoadFile( $file );

   my %x16header  = ();
   my %x16data    = ();

   my ($owner) = 'U'; # default is Universal
   foreach my $okey (sort keys %$ownerMap)
   {
      next unless $file =~ /$okey/;
      $owner = $ownerMap->{ $okey } if $ownerMap->{ $okey };
   }

   my $hdr     = $yaml->{ header };

   my $name     = $hdr->{ shipname };
   my $qsp      = $hdr->{ qsp };
   my $tl       = $hdr->{ tl };
   my $cost     = int $hdr->{ totalMCr };
   my $crew     = $hdr->{ crew };
   my $pass     = $hdr->{ passengers };
   my $bridge   = 0;
      $bridge   = 3 if $hdr->{ spaciousness } > 1.5;
      $bridge   = 1 if $hdr->{ spaciousness } < 1;
   my $demand   = $hdr->{ 'demand' } + 5;
   my $comfort  = $hdr->{ 'crewComfort' } + 5;
   my $tons     = $hdr->{ 'tons' };
   my $cargop   = int(100 * $hdr->{ 'totalCargoSpace' } / $tons);
   my $fuelp    = int(100 * ($hdr->{ 'powerFuelPercentage' } * $hdr->{ 'pf' } + $hdr->{ 'jumpFuelPercentage' } * $hdr->{ 'jf' } ));

   my ($ignoremission, $hull, $config, $maneuver, $jump) = $qsp =~ /(\w\w?)-(.)(.)(.)(.)/;

   my $mission = $hdr->{ 'mission' };
   
   #
   # siz = $tons / 100;
   #
   my $siz = int($tons/100);

   %x16header = ( 
	qsp		=> $qsp,
	classname 	=> uc substr($name, 0, 31),
	mission   	=> uc $mission,
	siz  	 	=> $siz,
	cfg		=> uc $config,
	mnv		=> $maneuver,
	jmp		=> $jump,
	hop		=> 0,
	landers		=> 'S',
	mcr		=> $cost,
	comfort		=> $comfort,
	demand		=> $demand,
	av		=> $tl,
	cargop		=> $cargop,
        fuelp 		=> $fuelp,
	owner		=> $owner,
   );

   my @comp = @{$yaml->{ components }};
   foreach my $component (@comp)
   {
      my $label     = $component->{ 'label' };
      my $rating    = $component->{ 'rating' };
      my $totalTons = $component->{ 'totalTons' };
      my $count     = $component->{ 'howMany'   };

      my $quality = 32 
                  + $component->{ 'q' }
                  + $component->{ 'r' }
                  + $component->{ 'e' }
                  + $component->{ 'b' }
                  + $component->{ 's' }
                  + $component->{ 'eff' };

      ##########################################################
      #
      #   We convert and organize based on type and category.
      #
      ##########################################################
      my $type  = $component->{ 'type' };
      my $thing = $component->{ 'category' }; 
      my $mount = '';

      if ( $thing =~ /AV=(\d+)/ )
      {
         $x16header{ 'av' } = $1;
         next;
      }

      $thing =~ s/'//g;

      $thing = $1 if $thing =~ /(Model.\d)/;
      $thing = "Model/$1" if $thing =~ /Computer M(\d)/;

      if ( $thing =~ /Model.(\d)/ )
      {
         $rating    = $1;
         $count     = 0;
         $totalTons = 0;
         $thing  = "Computer";
         $x16header{ 'computer' } = $rating;
      }

      $thing =~ s/(Vd|Or|Fo|DS|SR|LR|G|L|D) //;
      ($mount, $thing) = ($1, $3) if $thing =~ /(T1|T2|T3|T4|M|B|Surf|Bay|LBay|Ant|Ext|B1|B2)(de)? (.*)/;

      if ( $mount =~ /T1|T2|T3|T4|M|B|Surf|LBay|Bay|Ant|Ext|B1|B2/ )
      {
         $totalTons = 0; # size means nothing?
         $rating += 1 if $mount eq 'T2';
         $rating += 2 if $mount eq 'T3';
         $rating += 3 if $mount eq 'Ant';
         $rating += 4 if $mount eq 'T4';
         $rating += 5 if $mount eq 'B1';
         $rating += 6 if $mount eq 'B2';
         $rating += 6 if $mount eq 'Ext';
         $rating += 7 if $mount eq 'Bay';
         $rating += 8 if $mount eq 'LBay';
         $rating += 9 if $mount eq 'M';
      }

      next if $thing =~ /jump field/;
      next if $thing =~ /Space/;
      next if $thing eq 'Empty' || $thing eq 'Computer';
      next if $thing eq 'fittings'; # we're gonna ignore submersible hulls
      next if $thing eq 'wings'   ; # we're gonna ignore wings and fins

      $thing = 'Maneuver Drive' if $thing =~ /Gravitic Drive/;
      $thing = 'Jump Drive'     if $thing =~ /NAFAL/;
      $thing = 'Particle Accelerator' if $thing =~ /Particle Accelerator/;
      $thing = 'Life Support' if $thing =~ /Life Support/;

      if ($thing =~ /Fuel|Transfer Pump/)
      {
         $thing = 'Fuel Scoops' if $thing =~ /Scoops|Intakes|Bins|Transfer/;
         $thing = 'Fuel' if $thing =~ /Jump|Power/;
      }
      elsif ($thing eq 'landers')
      {
         $thing = 'L' if $label =~ /Legs/i;
         $thing = 'W' if $label =~ /Wheel/i;
         $thing = '-' if $label =~ /No /i;
         $x16header{ 'landers' } = $thing;
         next;
      }
      elsif ( $thing eq '' || $thing eq 'Hull' ) # huh, what is this thing?
      {
         $thing = "IGNORED THING[$label]";
         $thing = 'Barracks'     if $label =~ /Barracks/;
         $thing = 'Stateroom'    if $label =~ /Stateroom|Suite/;
         $thing = 'Life Support' if $label =~ /Life Support/;
         $thing = 'Low Berth'    if $label eq 'Low Berth';
         $thing = 'Vault'        if $label =~ /Vault/;
         $thing = 'Capture Tank' if $label =~ /(Capture|Animal) Tank/;
      }

      $type = 'Ops' if $thing eq 'Life Support';
      $type = 'Payload' if $type eq 'Passenger';
      $type = 'Engineering' if $type eq 'Drives';
      $type = 'Ops' if $thing eq 'Barracks';

      next if $thing =~ /IGNORED THING/;
      next if $type eq 'Crew';

      $totalTons = 0 if $thing =~ /Stateroom|Berth/;  # force to not use vol as rating
      $totalTons = 0 if $type  =~ /Weapon|Defense/;   # force to not use vol as rating

      $rating = $count if $type =~ /Weapon|Defense/;

      my $object = {
		q    	 => $quality,
		r        => $rating || $totalTons || $count,
#		_rating  => $rating,
#		_count   => $count,
#		_tons    => $totalTons,
                _thing   => $thing,
      };

#      if ( $label =~ /Stateroom|Low Berth|Stasis Berth/ )
#      {
#         my $count += $component->{ 'howMany' };
#      }

      if ( $label =~ /Standard controls/i )
      {
         $bridge = 2;
      }

      $deviceMap{ $type }->{ $thing }++;

      my $devID = $componentIDs->{ $thing };

      #if ( $x16data{ $type }->{ $devID } ) # one's already there!
      if ( $x16data{ $devID } ) # one's already there!
      {
         #$x16data{ $type }->{ $devID }->{ 'r' } += $object->{ 'r' };
         $x16data{ $devID }->{ 'r' } += $object->{ 'r' };
      }
      else
      {
         #$x16data{ $type }->{ $devID } = $object;
         $x16data{ $devID } = $object;
      }
   }
   #$x16data{ 'Ops' }->{ 1 }->{ 'r' } = $bridge; # bridge rating
   $x16data{ 1 }->{ 'r' } = $bridge; # bridge rating
   $ships++;

   printShipRecord(\%x16header, \%x16data);
   #print Dumper \%x16header;
   #print Dumper %x16data;
}

# print @list;
# print join "\n\n", sort values %catalog;


#   foreach my $type (sort keys %deviceMap)
#   {
#      print "$type\n";
#      my $val = $typemap{ $type } * 32;
#      my $mapref = $deviceMap{ $type };
#      foreach my $k2 (sort keys %$mapref)
#      {
#          printf "   %-20s => %d,\n", "$k2", $mapref->{ $k2 };
#      }
#   }


sub printShipRecord # ( %x16header, %x16data )
{
   my $hdrref = shift;
   my $datref = shift;
   my %hdr = %$hdrref;
   my %dat = %$datref;

=pod
   printf "%-23s %2s : %3d %s %d %d %d : %s %2d %2d %3d %2d %2d\n",
	$hdr{classname}, 
	$hdr{mission} 	,
	$hdr{siz} ,
	$hdr{cfg} ,
	$hdr{mnv} ,
	$hdr{jmp} ,
	$hdr{hop} ,
	$hdr{landers} ,
	$hdr{comfort} ,
	$hdr{demand} ,
	$hdr{av} ,
	$hdr{cargop} ,
	$hdr{fuelp};
=cut

   my $owner = $hdr{owner};
   my $qsp   = $hdr{qsp};
   my $class = $hdr{classname};

   my $outshipname = uc "$owner-$qsp-$class.BIN";
   open OUT, '>', $outshipname;
   
   print OUT pack 'A31x', $hdr{classname};
   print OUT pack 'A2',   $hdr{mission};
   print OUT pack 'C',    $hdr{siz};
   print OUT pack 'A',    $hdr{cfg};
   print OUT pack 'CCCC', $hdr{mnv}, $hdr{jmp}, $hdr{hop}, $hdr{computer};
   print OUT pack 'ACCC', $hdr{landers}, $hdr{comfort}, $hdr{demand}, $hdr{av};
   print OUT pack 'CC',   $hdr{cargop}, $hdr{fuelp};
   print OUT pack 'A',    $hdr{owner};
   print OUT pack 'A',    '-';    # placeholder

   my $devbytecount = 0;
   foreach my $id (sort { $a <=> $b } keys %dat)
   {
      my $obj  = $dat{$id};
      my $type = $id >> 5;
      my $q    = $obj->{ 'q' };
      my $r    = $obj->{ 'r' };
      my $desc = $obj->{'_thing'};
#      printf " - $type :  #%3d  q:%2d  r:%3d  $desc\n", $id, $q, $r;
      print OUT pack 'CCCC', $id, $q, $r, 1;
      $devbytecount += 4;
   }

#   print "Ship record size: ", $devbytecount + 48, "\n";

   for ($devbytecount .. 111)
   {
      print OUT pack 'x';
   }

   close OUT;
   print STDERR "Wrote $outshipname.\n";
}


sub mapOwner
{
   return 
   {
	'Aslan'			=> 'A',
	'Baraccai Technum'	=> 'I',
	'Bilstein'		=> 'I',
	'Al Morai'		=> 'I',
	'Droyne'		=> 'D',
	'Hiver'			=> 'H',
	'Imperial'		=> 'I',
	'Kkree'			=> 'K',
	'Oberlindes'		=> 'I',
	'Sword Worlds'		=> 'S',
	'Tukera'		=> 'I',
	'Vargr'			=> 'V',
	'Zhodani'		=> 'Z',

	'Chamaxi'		=> 'X',
	'Darrian'		=> 'R',
	'Humbolt'		=> 'U',
	'Kursae'		=> 'E',
	'Republic of Regina'	=> 'P',
	'Valtra'		=> 'T',
   };
}



sub getComponentMap
{
   return {
# Ops 000xxxxx
   Barracks             => 0,
   Bridge               => 1,
   Computer 		=> 2,
   'Life Support'       => 3,
   CommPlus             => 4,
   Communicator         => 5,
   HoloVisor            => 6,
   Visor                => 7,
   Scope                => 8,
# Sensor 001xxxxx
   Densitometer         => 32,
   EMS                  => 33,
   'Neutrino Detector'  => 34,
   Proximeter           => 35,
   'Grav Sensor'        => 36,
   'Life Detector'      => 37,
   'Activity Sensor'    => 38,
   'Deep Radar'         => 39,
   'Mass Sensor'        => 40,
   'Field Sensor'       => 41,
# Drive 010xxxxx 
    Fuel                => 64,
   'Fuel Purifiers'     => 65,
   'Fuel Scoops'        => 66,
   'Jump Drive'         => 67,
   'Maneuver Drive'     => 68,
   PowerPlant           => 69,
   'Hop Drive'          => 70,
   Collector            => 71,
   'Antimatter Plant'   => 72,
# Payload 011xxxxx
   'Capture Tank'       => 96,
    Cargo               => 97,
   'Low Berth'          => 98,
   Stateroom            => 99,
   Vault                => 100,
# Weapon 100xxxxx
   'Hybrid L-S-M'       => 128,
   Missile              => 129,
   'Beam Laser'         => 130,
   'Pulse Laser'        => 131,
   'Mining Laser'       => 132,
   'Particle Accelerator' => 133,
   'Meson Gun'          => 134,
   'Plasma Gun'         => 135,
   'Fusion Gun'         => 136,
   'Jump Damper'        => 137,
   'KK Missile'         => 138,
   CommCaster           => 139,
   DataCaster           => 140,
   Disruptor            => 141,
   Ortillery            => 142,
   'Salvo Rack'         => 143,
   'Tractor/Pressor'    => 144,
   'AM Missile'         => 145,
# Defense 101xxxxx
   Sandcaster           => 160,
   Jammer               => 161,
   'Stealth Mask'       => 162,
   'Black Globe'        => 163,
   'Grav Scrambler'     => 164,
   'Mag Scrambler'      => 165,
   'Meson Screen'       => 166,
   'Nuclear Damper'     => 167,
   }
}
