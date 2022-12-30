package ACS;
#
#  A convenient package for manipulating ACS YAML starship design files.
#
use strict;

my $y;
my $hdr;
my @components;
my @ehex           = ( 0..9, 'A'..'H', 'J'..'N', 'P'..'Z' );

sub init # pass in the YAML ref please
{  
   $y = shift or die "ACS.pm -- init() requires a YAML ref.\n";
   $hdr = $y->{ 'header' };
   @components = @{$y->{ 'components' }};
}

##########################################################################
#
#  Data Extraction
#
##########################################################################
# my $name   = $hdr->{ 'shipname' };
# my $qsp    = $hdr->{ 'qsp' };
# my $owner  = $hdr->{ 'owner' };
# my ($mission,$hullcode,$config,$m,$j) = $qsp =~ /^(\w+)-(.)(.)(.)(.)/;

#my $tons   = $hdr->{ 'tons' };
#my $missionLabel = $hdr->{ 'missionLabel' };
#my $comment = $hdr->{ 'comments' };

#my @comments = split '\.', $comment;
#$comment = $comments[0] . '.'; # just take the 1st sentence

#my $tl       = $hdr->{ 'tl' };
#my $computer = getComputerRating( @components );
#my $pp       = getPowerPlantRating( @components );
#my $mcr      = $hdr->{ 'totalMCr' };

#################################################################
#
#  Use Mission Code to determine if a ship is martial or not.
#
#################################################################
sub isMartial { return $hdr->{ 'qsp' } =~ /^[CDEGPQSVX]/ || 0 };


#################################################################
#
#  Find all components matching the passed-in type.  Valid types:
#
#     Hull
#     Armor
#     Drive
#     Sensor
#     Weapon
#     Defense
#     Ops
#     Crew
#     Payload
#     Passenger
#     Vehicle
#
#################################################################
sub grepByType
{
   my $type = shift;
   my @list = @components;

   return () unless @list;

   my @out = ();
   foreach my $item (@list)
   {
      push @out, $item if $item->{ 'type' } eq $type;
   }
   return @out;
}

#
#  Assume there's only one of these (e.g. computer, jump drive).
#
sub grepCategory
{
   my $category = shift;
   foreach my $item (@components)
   {
      return $item if $item->{ category } eq $category;
   }
   return undef;
}

#################################################################
#
#  Find the ship's computer then return the base model number.
#
#################################################################
sub getComputerRating
{
   my @components = @_;

   foreach my $comp (@components)
   {
      return $1 if $comp->{ 'mount' } =~ /Model.(\d)/;
   }
   return 0; # unknown
}

#################################################################
#
#  Return the tonnage of the main gun, else zero (0).
#
#################################################################
sub getMainGunTonnage
{
   my @weaponData = @_;

   foreach my $weaponRef (@weaponData)
   {
      if ($weaponRef->{ 'mount' } eq 'M') # found it
      {
         return $weaponRef->{ 'tons' };
      }
   }
   return 0; # no main gun found
}

sub getTonnageByMount
{
   my $mount = shift;
   my $tonnage = 0;

   foreach my $itemRef (@components)
   {
      if ($itemRef->{ 'mount' } eq $mount)
      {
         my $count = $itemRef->{ 'howMany' } || 1;
         $tonnage += $itemRef->{ 'tons' } * $count;
      }
   }
   return $tonnage;
}

sub getTonnageByMountRx
{
   my $mountRx = shift;
   my $tonnage = 0;

   foreach my $itemRef (@components)
   {
      if ($itemRef->{ 'mount' } =~ /$mountRx/)
      {
         my $count = $itemRef->{ 'howMany' } || 1;
         $tonnage += $itemRef->{ 'tons' } * $count;
      }
   }
   return $tonnage;
}

#################################################################
#
#   Figure out the small craft situation.
#
#################################################################
sub getSmallCraft()
{

}






1; # return 1 as all good Perl modules should

