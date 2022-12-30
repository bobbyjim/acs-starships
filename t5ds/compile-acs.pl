use YAML;

$/ = undef;
my %catalog;
my $ships = 0;
foreach my $file (<*.acs.txt>)
{
   print STDERR "$file\n";
   my $yaml = YAML::LoadFile( $file );

   my $date    = $yaml->{ 'ACS1.0' };
   my $mission = $yaml->{ 'Mission' };
   my $qsp     = $yaml->{ 'QSP' };
   my ($missionCode, $dash, $hullCode, $configCode, $maneuver, $jump) = split //, $qsp;
   my $tl      = $yaml->{ 'TL' };
   my $name    = $yaml->{ 'Name' };
   my $tons    = $yaml->{ 'Tons' };
   my $actualTons = $yaml->{ 'Actual Tons' };
   my $free    = $tons - $actualTons;
   my $mcr     = $yaml->{ 'MCr' };
   my $owner   = $yaml->{ 'Owner' };
   my $alleg   = $yaml->{ 'Allegiance' };
   my $comfort = $yaml->{ 'Crew comfort' };
   my $demand  = $yaml->{ 'Passenger demand' };
   my $cargo   = $yaml->{ 'Cargo' };
#   my $fuel    = int($yaml->{ 'FuelPercentage' } * $tons / 100);
   my $notes   = $yaml->{ 'Comments' };

   my @comp = @{$yaml->{ 'Components' }};
   my $computer = '?';
   my $lb       = 0;
   my $pp       = '?';
   my $fuel     = '?';
   my $crew     = '?';
   my $pass     = '?';

   foreach my $component (@comp)
   {
      
      if ( $component->{ 'category' } eq 'PowerPlant' )
      {
         $pp = $component->{ 'rating' };
      }
      elsif ( $component->{ 'category' } =~ /(Powerplant|Jump) Fuel/ )
      {
         $fuel += $component->{ 'totalTons' };
         # if ( $component->{ 'category' } eq 'Powerplant Fuel' )
         # {
         #    $duration = $component->{ 'notes' };
         # }
      }
      elsif ( $component->{ 'name' } eq 'Computer' )
      {
         $computer = $component->{ 'label' };
      }
      elsif ( $component->{ 'label' } eq 'Low Berth' )
      {
         $lb = $component->{ 'howMany' };
      }
   }
   $ships++;

   my $data = sprintf( "%10s,%4d,%-30s,%2d,%3d,%d,%d,%d,%4d,%12s,%3.2f,%22s,%2d,%2d,%2d\n",
      $owner, $tons, $name, $tl, $free, $maneuver, $jump, $pp, $fuel, $duration, $cost, $comp,
      $crew, $pass, $lb );

   $catalog{ $name } = $data;

   last;
}

print join "", sort values %catalog;
