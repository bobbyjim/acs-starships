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
      foreach my $fieldname (keys %$component)
      {
         $catalog{ $fieldname }++;
      }
   }
   $ships++;
}

print "Field usage across $ships ship designs:\n\n";
print join "\n", sort keys %catalog;
