use lib '.';
use AcsYAML2Acs;
use strict;

die "SYNOPSIS: $0 ship...\n" unless @ARGV;

my $verbose = 0;
foreach my $file (@ARGV)
{
   if ( $file =~ /^-/ ) # command switch
   {
      $verbose = 1 if $file eq "-v";
   }
   else
   {
      AcsYAML2Acs::convertFile( $file, $verbose );
   }
}
