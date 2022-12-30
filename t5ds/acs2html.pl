use lib '.';
use AcsYAML2Html;
use strict;

foreach my $file (@ARGV)
{
   AcsYAML2Html::convertFile( $file );
}
