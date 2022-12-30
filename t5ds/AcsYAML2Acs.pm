package AcsYAML2Acs;
use YAML;
use strict;

sub convertFile
{
   my $file    = shift;
   my $verbose = shift || 0;

   $file =~ s/\.yml$//;
   $file =~ s/\.yaml$//;

   $file .= '.' unless $file =~ /\.$/;
   $file .= 'yml' unless $file =~ /yml$/; 

   my $outfile = $file;
   $outfile =~ s/\.yml$/.acs.txt/;
   print STDERR "Infile: $file   Outfile: $outfile\n";

   my $yaml = YAML::LoadFile( $file );

   my ($allegiance) = $file =~ /^(\w{2,4})/;
   my $string = convert( $yaml, $allegiance );
   open OUT, '>', $outfile;
   print OUT $string;
   close OUT;

   print $string if $verbose;
}

#
#
#  A pile of rules that reorganizes the old components along newer lines of thought.
#
#  Types: Hull, Armor, Drive, Sensor, Weapon, Defense, Ops, Crew, Payload, Passenger, Vehicle
#
sub applyComponentAdjustmentRules
{
   my @comp = @_;
   my $tmp  = '';

   for my $component (@comp)
   {
      $component->{ 'label' } =~ s|Hull.*?\d+ a\/l free|Hull|;
      
      $component->{ 'type' } = 'Payload' if $component->{ 'type'  } eq 'Passenger';
      $component->{ 'type' } = 'Payload' if $component->{ 'label' } =~ /Low Berth/;

      $component->{ 'capacity' } = $component->{ 'sleeps' } if $component->{ 'sleeps' };
      $component->{ 'capacity' } = 2 if $component->{ 'label' } =~ /Common Fresher/i;
      $component->{ 'capacity' } = 1 if $component->{ 'label' } =~ /Shared Fresher/i;
      $component->{ 'rating' } = 'H' if $component->{ 'label' } =~ /Life Support Short Term/i;
      $component->{ 'rating' } = 'S' if $component->{ 'label' } =~ /Life Support Standard/i;
      $component->{ 'rating' } = 'L' if $component->{ 'label' } =~ /Life Support Long Term/i;
      $component->{ 'rating' } = 'U' if $component->{ 'label' } =~ /Life Support Luxury/i;
      $component->{ 'rating' } = 'A' if $component->{ 'label' } =~ /Life Support Adaptable/i;

      # if ($component->{ 'type' } eq 'Drive' && $component->{ 'category'} !~ /Fuel/) # not fuel
      # {  # swap mod and rating
      #    $tmp = $component->{ 'rating' };
      #    $component->{ 'rating' } = $component->{ 'mod' };
      #    $component->{ 'mod' }    = $component->{ 'rating' };
      # }

      $component->{ 'category' } = 'Med'       if $component->{ 'label' } =~ /Med Console|Medical|Surgery|Clinic/i;
      $component->{ 'category' } = 'Life'      if $component->{ 'label' } =~ /Life Support/i;
      $component->{ 'category' } = 'Magazine'  if $component->{ 'label' } eq 'Magazine';
      $component->{ 'category' } = 'Low'       if $component->{ 'label' } =~ /Low Berth/;
      $component->{ 'category' } = 'Stateroom' if $component->{ 'label' } =~ /(Crew|Spacer) (Stateroom|Niche|Suite|Double|Triple|Cramped|Bunks|Hotbunks)/i;
      $component->{ 'category' } = 'Stateroom' if $component->{ 'label' } =~ /Stateroom|Suite|Stateroom Double|Stateroom Triple|Stateroom Cramped|Steerage/;
      $component->{ 'category' } = 'Commons'   if $component->{ 'label' } =~ /Commons|Lounge/;
      $component->{ 'category' } = 'Fresher'   if $component->{ 'label' } =~ /Fresher/;

      $component->{ 'category' } = 'Fuel'     if $component->{ 'category' } =~ / Fuel/;
      $component->{ 'category' } = 'Armor'    if $component->{ 'category' } =~ /^AV=([123456789]\d*). /;
      $component->{ 'category' } = 'Coating'  if $component->{ 'category' } =~ /^AV=0. /;
      $component->{ 'category' } = 'Computer' if $component->{ 'category' } =~ /^Computer/ || $component->{ 'label' } =~ /Non-Bridge Console/i; 
      $component->{ 'rating'   } = delete $component->{ 'mod' } if $component->{ 'category' } =~ /^Computer/;
      $component->{ 'category' } = $component->{ 'config' }
         if $component->{ 'config'   } =~ /Weapon|Sensor|Defense/;

      $component->{ 'rating' } = $1 if /^AV=([^0]\d*)/;
      $component->{ 'label' } =~ s/^AV=[^0]\d+. /Armor: /;
      $component->{ 'label' } =~ s/^AV=0. c /Coating: /;

   }
}

sub countRequiredCrewType
{
   my $type = lc shift;
   my $comments = lc shift;
   my ($found, $required) = $comments =~ /(require|the ship has).*?crew[^.]*?:([^.]*?)\./i;

   #print STDERR "required: [$required]\n" if $required =~ /\S/;
   my $count = 0;
   $count = 1 if $required =~ /$type/;
   return '' if $count == 0;

   $count = 2 if $required =~ /(2|two) $type/i;
   $count = 3 if $required =~ /(3|three) $type/i;
   $count = 4 if $required =~ /(4|four) $type/i;
   $count = 5 if $required =~ /(5|five) $type/i;
   $count = 6 if $required =~ /(6|six) $type/i;
   $count = 7 if $required =~ /(7|seven) $type/i;
   $count = 8 if $required =~ /(8|eight) $type/i;

   return $count;
}

sub countNonRequiredCrewType
{
   my $type = lc shift;
   my $comments = lc shift;
   my ($found, $notreq) = $comments =~ /(require|the ship has).*?crew[^.]*?:[^.]*?\. (.*)/i;

   my $count = 0;
   $count = 1 if $notreq =~ /$type/;
   return '' if $count == 0;

   $notreq =~ s/(small craft|pinnace|fighter|gig) //i;

   $count = 2 if $notreq =~ /(2|two) $type/i;
   $count = 3 if $notreq =~ /(3|three) $type/i;
   $count = 4 if $notreq =~ /(4|four) $type/i;
   $count = 5 if $notreq =~ /(5|five) $type/i;
   $count = 6 if $notreq =~ /(6|six) $type/i;
   $count = 7 if $notreq =~ /(7|seven) $type/i;
   $count = 8 if $notreq =~ /(8|eight) $type/i;
   $count = 9 if $notreq =~ /(9|nine) $type/i;
   $count = 10 if $notreq =~ /(10|ten) $type/i;

   return $count;
}

sub parseCrewExtension
{
   my $comments = shift;
   return '' unless $comments;

   my $cx = '';
   
   $cx .= 'A' x countRequiredCrewType('Pilot',         $comments);
   $cx .= 'B' x countRequiredCrewType('Astrogator',    $comments);
   $cx .= 'C' x countRequiredCrewType('Engineer',      $comments);
   $cx .= 'I' x countRequiredCrewType('Drive Tech',    $comments);
   $cx .= 'D' x countRequiredCrewType('Medic',         $comments);
   $cx .= 'E' x countRequiredCrewType('Steward',       $comments);
   $cx .= 'E' x countRequiredCrewType('Purser',        $comments);
   $cx .= 'F' x countRequiredCrewType('Freightmaster', $comments);
   $cx .= 'G' x countRequiredCrewType('Sensop',        $comments);
   $cx .= 'G' x countRequiredCrewType('Sensor Tech',   $comments);
   $cx .= 'L' x countRequiredCrewType('Counsellor',    $comments);
   $cx .= 'P' x countRequiredCrewType('Troop',         $comments);
   $cx .= 'T' x countRequiredCrewType('Gunner',        $comments);

   my $total = 0
   + countRequiredCrewType('Pilot',         $comments)
   + countRequiredCrewType('Astrogator',    $comments)
   + countRequiredCrewType('Engineer',      $comments)
   + countRequiredCrewType('Drive Tech',    $comments)
   + countRequiredCrewType('Medic',         $comments)
   + countRequiredCrewType('Steward',       $comments)
   + countRequiredCrewType('Purser',        $comments)
   + countRequiredCrewType('Freightmaster', $comments)
   + countRequiredCrewType('Sensop',        $comments)
   + countRequiredCrewType('Sensor Tech',   $comments)
   + countRequiredCrewType('Counsellor',    $comments)
   + countRequiredCrewType('Troop',         $comments)
   + countRequiredCrewType('Gunner',        $comments);

   $cx = $total if $total > 8;

=pod
   $cx .= '.';

   $cx .= 'A' x countNonRequiredCrewType('Pilot',         $comments);
   $cx .= 'B' x countNonRequiredCrewType('Astrogator',    $comments);
   $cx .= 'C' x countNonRequiredCrewType('Engineer',      $comments);
   $cx .= 'I' x countNonRequiredCrewType('Drive Tech',    $comments);
   $cx .= 'D' x countNonRequiredCrewType('Medic',         $comments);
   $cx .= 'E' x countNonRequiredCrewType('Steward',       $comments);
   $cx .= 'E' x countNonRequiredCrewType('Purser',        $comments);
   $cx .= 'F' x countNonRequiredCrewType('Freightmaster', $comments);
   $cx .= 'G' x countNonRequiredCrewType('Sensop',        $comments);
   $cx .= 'G' x countNonRequiredCrewType('Sensor Tech',   $comments);
   $cx .= 'L' x countNonRequiredCrewType('Counsellor',    $comments);
   $cx .= 'P' x countNonRequiredCrewType('Troop',         $comments);
   $cx .= 'T' x countNonRequiredCrewType('Gunner',        $comments);

   $cx =~ s/\.$//;
=cut

   return $cx;
}

sub buildVehicleExtension
{
   my @components = @_;
   my %vehicles = ();
   foreach my $obj (@components)
   {
      next unless $obj->{ 'type' } eq 'Vehicle';
      my $code = $obj->{ 'code' };
      $code =~ s/^.*(.)$/$1/; 
      $vehicles{ $code } += $obj->{ 'howMany'} if $code;
   }
   my @vx = ();
   foreach (sort keys %vehicles)
   {
      push @vx, $_ . $vehicles{ $_ };
   }
   return join ' ', @vx;
}

sub fetchFuelTreatment
{
   my @components = @_;
   my @fuelTreatment = ();
   foreach my $obj (@components)
   {
      if ($obj->{ 'category' } eq 'Fuel Scoops' )
      {
         push @fuelTreatment, $obj->{ 'code' };
      }
      elsif ($obj->{ 'category' } eq 'Fuel Bins' )
      {
         push @fuelTreatment, $obj->{ 'code' };
      }
      elsif ($obj->{ 'category' } eq 'Fuel Intakes' )
      {
         push @fuelTreatment, $obj->{ 'code' };
      }
   }
   return join ',', @fuelTreatment;
}

sub fetchLowBerths
{
   my @components = @_;
   foreach my $obj (@components)
   {
      if ($obj->{ 'label' } eq 'Low Berth' )
      {
         return $obj->{ 'howMany' };
      }
   }
}

sub fetchComputerModel
{
   my @components = @_;
   foreach my $obj (@components)
   {
      if ($obj->{ 'name' } eq 'Computer' )
      {
         my $label = $obj->{ 'label' };
         $label =~ s/^Computer //;
         return $label;
      }
   }
}

sub convert
{
   my $yaml = shift;
   my $allegiance = shift;

   my $hdr     = $yaml->{ header };

   my $missionLabel = $hdr->{ missionLabel };
   my $qsp      = $hdr->{ qsp };
   my $shipname = $hdr->{ shipname };
   my $totalMCr = $hdr->{ totalMCr };
   my $comments = $hdr->{ comments };

   $comments =~ s/\n/\n   /g;
   $comments = "   $comments";

   my $builder  = $hdr->{ builder };
   my $owner    = $hdr->{ owner };
   my $disposition = $hdr->{ disposition };
   my $arch     = $hdr->{ architect };

   my $dataBlock1 = '';
      $dataBlock1 .= "Builder: $builder\n" if $builder;
      $dataBlock1 .= "Owner: $owner\n" if $owner;
      $dataBlock1 .= "Disposition: $disposition\n" if $disposition;
      $dataBlock1 .= "Allegiance: $allegiance\n" if $allegiance;
      $dataBlock1 .= "Architect: $arch\n" if $arch;

   my $tons     = $hdr->{ tons };
   my $tonsFree = $hdr->{ tonsFree };
   my $cargo    = $hdr->{ 'totalCargoSpace' };
   my $fuel     = int($tons*($hdr->{ 'powerFuelPercentage' } * $hdr->{ 'pf' } + $hdr->{ 'jumpFuelPercentage' } * $hdr->{ 'jf' }));
   
   my $vol = '';
   
   $vol = "Undertonnage: $tonsFree"    if $tonsFree > 0;
   $vol = "Overtonnage: " . -$tonsFree if $tonsFree < 0;

   my $crewComfort = $hdr->{ crewComfort };
   my $demand      = $hdr->{ demand };

   my $tl       = $hdr->{ tl };
   my ($mission, $dash, $hull, $config, $maneuver, $jump) = split //, $hdr->{ qsp };
   my $crew     = $hdr->{ crew };
   my $pass     = $hdr->{ passengers };

   my $comments = $hdr->{ comments }; # uh oh
   chomp $comments;
   $comments =~ s/\n/\n   /g;
   $comments = "   $comments";

   my $crewExtension = parseCrewExtension( $comments );

   my @comp = @{$yaml->{ components }};

   my $low      = fetchLowBerths( @comp );
   my $model    = fetchComputerModel(@comp);
   my $vx       = buildVehicleExtension( @comp );
   my $fuelTreatment = fetchFuelTreatment( @comp );

   applyComponentAdjustmentRules(@comp);

   my @hulldata        = grepByType( 'Hull',      @comp );
   my @armorData       = grepByType( 'Armor',     @comp );
   my @driveData       = grepByType( 'Drive',     @comp );  
   my @sensorData      = grepByType( 'Sensor',    @comp );			
   my @weaponData      = grepByType( 'Weapon',    @comp );
   my @defenseData     = grepByType( 'Defense',   @comp );		
   my @operationsData  = grepByType( 'Ops',       @comp );
   my @crewData        = grepByType( 'Crew',      @comp );
   my @payloadData     = grepByType( 'Payload',   @comp );
   my @paxData         = grepByType( 'Passenger', @comp );
   my @vehicleData     = grepByType( 'Vehicle',   @comp );

   my $today = scalar localtime;

   my $out =<<EOHEADER;
--- 
ACS1.0: $today
Mission: $missionLabel
QSP: $qsp 
Cx: $crewExtension
Vx: $vx
Name: $shipname
Tons: $tons
TL: $tl 
$vol
MCr: $totalMCr
$dataBlock1
Crew comfort: $crewComfort
Passengers: $pass
Passenger demand: $demand
Low berths: $low
Cargo: $cargo
Fuel: $fuel
Fuel treatment: $fuelTreatment
Computer: $model

Comments: |-
$comments

Components:
EOHEADER

   $out .= encode("04-07", "Hull", @hulldata, @armorData);
#   $out .= encode("08",    "Armor", @armorData);
   $out .= encode("10-11", "Drives", @driveData);
   $out .= encode("16",    "Operations", @operationsData);
   $out .= encode("21a",   "S-Sensors", filterSpaceRanged(@sensorData));
   $out .= encode("21b",   "W-Sensors", filterWorldRanged(@sensorData));
   $out .= encode("21b",   "Weapons", @weaponData);
   $out .= encode("21c",   "Defenses", @defenseData);
   $out .= encode("17-18", "Crew", @crewData);
   $out .= encode("20",    "Passengers", @paxData);
   $out .= encode("19",    "Payload", @payloadData);
   $out .= encode("16b",   "Vehicles", @vehicleData);

   $out .=<<EODONE;

ref: [<a href='http://www.farfuture.net/'>Far Future Enterprises</a>]

EODONE

   return $out;
}

sub filterSpaceRanged
{
   my @things = @_;
   my @filtered = ();
   for (@things)
   {
      push @filtered, $_ if $_->{ 'range' } =~ /DS|LR|AR|SR|FR/;
   }
   return @filtered;
}

sub filterWorldRanged
{
   my @things = @_;
   my @filtered = ();
   for (@things)
   {
      push @filtered, $_ if $_->{ 'range' } !~ /DS|LR|AR|SR|FR/;
   }
   return @filtered;
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

sub encode
{
   my $title     = shift;
   my $type      = shift;
   my @list      = @_;

   return '' unless @list;

   my @out = ();

   my @tlmap = ( 1 .. 9, 'A' .. 'H', 'J' .. 'N', 'P' .. 'Z' );
   my @qmap  = ( 0, 1, 2, 3, 4, 5, 'E', 'D', 'C', 'B', 'A' );

   #my $dashes = '-' x (1+(61-length($type))/2);
   #my $comment = "# $dashes $type $dashes";
   #chop $comment if length($comment) > 66;
   #push @out, "$comment\n";

   my $titleLabelThing = sprintf("%-32s", uc $type);
               #-    400   . Streamlined Hull                   26  ;HH0  S 00000
   push @out, "#\n";
   push @out, "#   TONS   # $titleLabelThing    MCR   CODE  R QREBS\n";
   push @out, "#  ----- --- -------------------------------- ------  ,---- -- -----\n";

   foreach my $obj (@list)
   {
      my $category = ucfirst $obj->{ 'category' }; # this should work

      my $count  = $obj->{ 'howMany' } || $obj->{ 'count' } || 1;
      my $tons   = $obj->{ 'tons' } || '0';
      my $totalTons = $tons * $count;

      my $av          = $obj->{ 'av' };
      my $code        = $obj->{ 'code' };
      my $cfg         = $obj->{ 'config' };
      my $efficiency  = $obj->{ 'eff' }; 
      my $mount       = $obj->{ 'mount' };
      my $label       = $obj->{ 'label' };
      my $range       = $obj->{ 'range' };
      my $rating      = $obj->{ 'rating' };
      my $stage       = $obj->{ 'stage' };
      my $mod;

      my $CP          = $obj->{ 'CP' };
      my $tl          = $obj->{ 'tl' };
      my $mcr         = $obj->{ 'mcr' } || '0';
      my $totalMCr    = $obj->{ 'totalMCr' } || $mcr * $count;
      my $ws          = $obj->{ 'ws' };
      my $op          = $obj->{ 'op' };
      my $cc          = $obj->{ 'cc' };

      $mod    = $rating;
      $rating = $obj->{ 'capacity' } || $obj->{ 'mod' } || $code;
      $rating = $1 if $code =~ /^(..)/; # just take the first 2 chars

      my ($qrebs, $r, $e, $b, $s) = ($obj->{ 'q' }, $obj->{ 'r' }, $obj->{ 'e' }, $obj->{ 'b' }, $obj->{ 's' });
      $qrebs .= $qmap[ $r ];
      $qrebs .= $qmap[ $e ];
      $qrebs .= $qmap[ $b ];
      $qrebs .= $qmap[ $s ];
      $qrebs = '.....' if $qrebs eq '00000';

      if ($obj->{ 'notes' } =~ /^(\d+)cc (\d+)op (\d+)ws/)
      {
         ($cc, $op, $ws) = ($1, $2, $3);
      }

      my $people = 0;
      if ($obj->{ 'notes' } =~ /^(\d+) (crew|pass)/i)
      {
         $people = $1;
      }

      # etc
      if ($label =~ /fresher/i)
      {
      }

      my ($typecode) = split '', $type;     # 1st char
      my ($catcode ) = split '', $category; # 1st char
      $catcode = 'F' if $label =~ /Fuel/i;

#
#     We want a nice, human-readable format, kind of like this:
#
#       8  16x Emergency Low Berth          1.6    ;PO0  - 00000 
#
#     This means we put a ceiling on the label.  32 chars wide.

      $count .= 'x' if $count > 1;
      $count = '.' if $count == 1;
   
      push @out, sprintf " - %5d %3s %-32s %6.1f  ,%s%s%s%s %2s %5s\n",
            $totalTons,
            $count,
            $label,
            $totalMCr,
            $typecode,
            $catcode || 'O',  # default to Ops :)
            $mod || '.',
            $CP,
            $rating || '.',
            $qrebs;

=pod
      push @out, sprintf " - %s%s%s %2s %2s %5s %-5s %-5s $label\n",
		$typecode,
                $catcode || 'O',  # default to Ops :)
		          $CP,
                $rating  || '-',
                $count,
                $qrebs,
		$tons,
		$mcr,
		;
=cut

   }

   return join "", @out;
}

1; # return 1 as all good perl packages should
