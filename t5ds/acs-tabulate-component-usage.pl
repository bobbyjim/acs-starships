use YAML;

$/ = undef;
my %catalog;
my $ships = 0;
foreach (<*.yml>)
{
   print "$_:\n";
   my $yaml = YAML::LoadFile( $_ );

   my @comp = @{$yaml->{ components }};

#   print "Components: ", scalar @comp, "\n";
   foreach my $component (@comp)
   {
      my $category = $component->{ category };
      $category =~ s/AV=\d+\. \d//;
      $catalog{ $component->{ 'type' } }->{ $category }++;
   }
   $ships++;

#   last if $ships == 10;
}

print "Component usage across $ships ship designs:\n";
print '-' x 80, "\n";
foreach my $type (sort keys %catalog)
{
   my $href = $catalog{ $type };
   foreach my $entry ( reverse sort { $href->{$a} <=> $href->{$b} } keys %$href )
   {
      print "$type :: $entry: ", $href->{ $entry }, "\n";
   }
}

__END__

   - 
      totalTons: 200
      howMany: 1
      totalMCr: 16
      eff: 1
      label: 'Streamlined Hull, lifters'
      name: 'Hull'
      mult: 1
      preMult: 1
      Sq: 400
      code: 'S'
      q: 0
      type: 'Hull'
      notes: 'S, lifters'
      s: 0
      CP: 0
      config: 'Streamlined'
      b: 0
      tl: 12
      tons: 200
      e: 0
      mcr: 16
      r: 0
      category: 'Hull'
      target: 12

   - 
      s: 0
      howMany: 1
      CP: 0
      b: 0
      eff: 1
      tl: 12
      totalTons: 72
      tons: 72
      totalMCr: 0
      e: 0
      mcr: 0
      label: 'Jump Fuel (4  parsecs)'
      Sq: 144
      r: 0
      category: 'Jump Fuel'
      q: 0
      target: 12
      type: 'Drive'
      notes: 'J4, 18t/pc'

