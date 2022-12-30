package AcsYAML2Html;
use YAML;
use strict;

sub convertFile
{
   my $file = shift;

   unless ($file =~ /\.yml$/)
   {
      $file =~ s/\.yaml$//;
      $file .= '.yml' 
   }
   my $outfile = $file;
   $outfile =~ s/\.yml$/.html/;
   print "Infile: $file   Outfile: $outfile\n";

   my $yaml = YAML::LoadFile( $file );

   my $string = convert( $yaml );
   open OUT, '>', $outfile;
   print OUT $string;
   close OUT;
}

sub convert
{
   my $yaml = shift;

   my $hdr     = $yaml->{ header };

   my $missionLabel = $hdr->{ missionLabel };
   my $qsp      = $hdr->{ qsp };
   my $shipname = $hdr->{ shipname };
   my $totalMCr = $hdr->{ totalMCr };
   my $comments = $hdr->{ comments };
   $comments =~ s|\n$||;
   $comments =~ s|\n|<br />\n|g;

   my $builder  = $hdr->{ builder };
   my $owner    = $hdr->{ owner };
   my $disposition = $hdr->{ disposition };

   my $dataBlock1 = '';
      $dataBlock1 .= "Builder: $builder<br />\n" if $builder;
      $dataBlock1 .= "Owner: $owner<br />\n" if $owner;
      $dataBlock1 .= "Disposition: $disposition<br />\n" if $disposition;

   my $tons     = $hdr->{ tons };
   my $tonsFree = $hdr->{ tonsFree };

   my $vol = "Volume: " . ($tons - $tonsFree) . " tons";

   $vol = "Overtonnage +" . (-1 * $tonsFree) . " tons" 
         if $tonsFree < 0;

   my $crewComfort = $hdr->{ crewComfort };
   my $demand      = $hdr->{ demand };

   $crewComfort = "+" . $crewComfort if $crewComfort > -1;
   $demand      = "+" . $demand      if $demand      > -1;

   my $tl       = $hdr->{ tl };
   my ($mission, $dash, $hull, $config, $maneuver, $jump) = split //, $hdr->{ qsp };
   my $cost     = $hdr->{ totalMCr };
   my $crew     = $hdr->{ crew };
   my $pass     = $hdr->{ passengers };

   my @comp = @{$yaml->{ components }};

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

   my $opsQuality = '';
   $opsQuality .= "Crew Comfort $crewComfort. " if $crewComfort != 0;
   $opsQuality .= "Demand $demand. " if $demand != 0;
   $opsQuality .= "$vol. " if $vol;
   $opsQuality .= "MCr $totalMCr.";
#   $opsQuality = "<p>$opsQuality</p>" if $opsQuality;

   my $out =<<EOHEADER;
<html>
<head>
<style type='text/css'>
<!--
p2 { font-size:16pt; font-style:italic; font-family:sans-serif; }
p  { font-size:9pt; font-family:sans-serif; }
th { font-size:16pt; font-family:sans-serif; border-style:none; }
td { font-size:9pt; font-family:sans-serif; border-style:none; }
-->
</style>
</head>
<body>

<p2>$shipname-class $missionLabel ($qsp)   MCr $totalMCr</p2>
<p>$dataBlock1</p>
<p>$comments</p>
<p>$opsQuality</p>

<hr />
<table rules='all' cellpadding='2' width='615px'>
EOHEADER

   $out .= encodeHtml("04-08", "Hull", @hulldata, @armorData);
#   $out .= encodeHtml("08", "Armor", @armorData);
   $out .= encodeHtml("10-11", "Drives", @driveData);
   $out .= encodeHtml("16", "Operations", @operationsData);
   $out .= encodeHtml("21", "Sensors", @sensorData);
   $out .= encodeHtml("21b", "Weapons", @weaponData);
   $out .= encodeHtml("21c", "Defenses", @defenseData);
   $out .= encodeHtml("17-18", "Crew", @crewData);
   $out .= encodeHtml("19-20", "Payload", @payloadData, @paxData);
#   $out .= encodeHtml("20", "Passengers", @paxData);
   $out .= encodeHtml("16b", "Vehicles", @vehicleData);

   $out .=<<EODONE;
</table>
[<a href='http://www.farfuture.net/'>Far Future Enterprises</a>]
</body>
</html>
EODONE

   return $out;
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

sub encodeHtml
{
   my $title     = shift;
   my $subtitle  = shift;
   my @list      = @_;

   return '' unless @list;
   
   my $body = '';
   my @bgcolor = ( 'ffffff', 'f8f8f8' );

   my $hasQuality = 0;

   foreach my $obj (@list)
   {
      my $count  = $obj->{ howMany } || 1;
      my $tons   = '-';
      $tons = ($obj->{ tons } * $count) if $obj->{ tons };
      $count = '' if $count == 1;

      my $label  = $obj->{ label };
      my $target = $obj->{ target };
      my ($q, $r, $e, $b, $s) = ($obj->{ q }, $obj->{ r }, $obj->{ e }, $obj->{ b }, $obj->{ s });
      my $CP     = $obj->{ CP };
      my $Sq     = $obj->{ Sq };
      my $tl     = $obj->{ tl };
      my $mcr    = $obj->{ mcr } || '-';

      my $notes = '';
      $notes .= $q > 1? "Q+$q " : $q < 0? "Q$q " : '';
      $notes .= $r > 1? "R+$q " : $r < 0? "R$r " : '';
      $notes .= $e > 1? "E+$q " : $e < 0? "E$e " : '';
      $notes .= $b > 1? "B+$q " : $b < 0? "B$b " : '';
      $notes .= $s > 1? "S+$q " : $s < 0? "S$s " : '';

      $hasQuality++ if $notes;

      $notes = $obj->{ notes } unless $notes; # if $obj->{ name } eq 'Bridge';

      $notes =~ s/^.*?(\d+)t per parsec/$1t per parsec/;

      $count = '' unless $count;
      $count = "($count) " if $count;
 
      $body .=<<EOLN;
<tr bgcolor='$bgcolor[0]'>
   <td>$tons</td>
   <td>$tl</td>
   <td>$count$label</td>
   <td>$mcr</td>
   <td>$notes</td>
</tr>
EOLN

      push @bgcolor, shift @bgcolor;
   }

   my $hdr  = writeHtmlHeaderLine( $title, $subtitle, 1 + scalar @list );

   return $hdr . $body;
}

sub writeHtmlHeaderLine
{
   my $title    = shift;
   my $subtitle = shift;
   my $rowspan  = shift;
#   my $notes    = shift;

   my $hdr =<<EOLN;

<tr bgcolor='d0d0d0'>
<th width=100px rowspan='$rowspan'><font size='-1'>$title<br />$subtitle</font></th>
   <td><i>Tons</i></td>
   <td><i>TL</i></td>
   <td><i>Component</i></td>
   <td><i>MCr</i></td>
EOLN

   #$hdr .= "   <td width=130px><i>Quality</i></td>\n" if $hasQuality;
   $hdr .= "   <td width=130px><i></i></td>\n"; 
   $hdr .= "</tr>\n";

   return $hdr;
}

1; # return 1 as all good perl packages should
