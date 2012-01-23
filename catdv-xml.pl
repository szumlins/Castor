#!/usr/bin/perl

# set up environment
# if you do not have XML::Simple installed, use CPAN to install
#
# shell> perl -MCPAN -e shell
# cpan> install XML::Simple

use XML::Simple;
use Data::Dumper;
use File::Basename;

if ($ARGV[0] eq '' && $ARGV[1] eq ''){
	print "\nusage: catdv-xml.pl debug|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml";
	exit	
}

if ($ARGV[0] eq 'debug' && $ARGV[1] eq ''){
	print "error: no XML file given\n\n";
	print "usage: catdv-xml.pl debug|media_file xml_file\n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml";
	exit	
}


$xml = new XML::Simple;

# user variable area
# where are your xml files going from CatDV (default /usr/local/catdv-presstore/tmp)
$xmldir = "/usr/local/catdv-presstore/tmp";

# get the base filename (similar to $f in CatDV)
$xmlfile = basename($ARGV[0]);

# add .xml to the end of filename to reference exported xml from CatDV
if($ARGV[0] eq "debug"){
	$xmltarget = $ARGV[1];
} else {
	$xmltarget = "$xmldir/$xmlfile.xml";
}

#read in CatDV xml file from command line
$data = $xml->XMLin($xmltarget);


# this next section will have to be set up to match your PresSTORE/CatDV settings.  
# first, place each of your PresSTORE metadata fields as array members below
# I have two metadata fields in my PresSTORE index, League and Event.  I start 
# with md1key, incrementing for each metadata field I want to add.  Make sure you
# use the internal name for the field.

$md1key = "league"; #Maps to USER13 in CatDV
$md2key = "event";  #Maps to USER15 in CatDV

# in this section, I pull the USER field from CatDV that I want to map to each metadata key.
# for this example, the name of Metadata field USER13 in CatDV is "League", USER15 is "Event".
# repeat until all your md keys line up with values read from the xml file

$md1value = $data->{CLIP}->{STATUS}; #This returns the value of CatDV field USER13
$md2value = $data->{CLIP}->{USER15}->{contents}; #This returns the value of CatDV field USER15

# echo output back to PresSTORE.  Simply add each of your key/value pairs to the next line.
# Don't forget to escape the curly braces for the values.
if($ARGV[2] eq 'dump'){
	print Dumper($data);
} else {
	print "$md1key \{$md1value\} $md2key \{$md2value\}\n";
}