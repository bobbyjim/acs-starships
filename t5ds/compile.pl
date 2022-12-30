use YAML;

$/ = undef;
my %catalog;
my $ships = 0;
foreach my $file (<*.yml>)
{
   print STDERR "$file\n";
   my $yaml = YAML::LoadFile( $file );

   my ($owner) = $file =~ /^(\w+)[ -]/;
   my $hdr     = $yaml->{ header };

   my $qsp      = $hdr->{ qsp };
   my $vol      = $hdr->{ tons };
   my $name     = $hdr->{ shipname };
   my $tl       = $hdr->{ tl };
   my $free     = $hdr->{ tonsFree };
   my ($mission, $dash, $hull, $config, $maneuver, $jump) = split //, $hdr->{ qsp };
   my $pp       = '';
   my $fuel     = 0;
   my $duration = '';
   my $cost     = $hdr->{ totalMCr };
   my $comp     = '';
   my $crew     = $hdr->{ crew };
   my $pass     = $hdr->{ passengers };
   my $lb       = 0;
   my $notes    = '';

   my @comp = @{$yaml->{ components }};

   foreach my $component (@comp)
   {
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
         $comp = $component->{ 'label' };
      }
      elsif ( $component->{ 'label' } eq 'Low Berth' )
      {
         $lb = $component->{ 'howMany' };
      }
   }
   $ships++;

   my $data = sprintf( "%10s,%4d,%-30s,%2d,%3d,%d,%d,%d,%4d,%12s,%3.2f,%22s,%2d,%2d,%2d\n",
      $owner, $vol, $name, $tl, $free, $maneuver, $jump, $pp, $fuel, $duration, $cost, $comp,
      $crew, $pass, $lb );

   $catalog{ $name } = $data;
}

print join "", sort values %catalog;
