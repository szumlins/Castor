#!/usr/bin/perl

# set up environment
# if you do not have XML::Simple installed, use CPAN to install
#
# shell> perl -MCPAN -e shell
# cpan> install XML::Simple

use XML::Simple;
use Data::Dumper;
use File::Basename;

require "conf/catdv.conf";


if ($ARGV[0] eq '' && $ARGV[1] eq ''){
	print "\nusage: catdv-xml.pl debug|media_file xml_file \n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml\n\n";
	exit	
}

if ($ARGV[0] eq 'debug' && $ARGV[1] eq ''){
	print "error: no XML file given\n\n";
	print "usage: catdv-xml.pl debug|media_file xml_file\n\n";
	print "debug: enables direct analysis of CatDV XML file\n";
	print "video_file: the full path of the original media location (ex. \"MyVideo.mov\")\n";
	print "xml_file: an exported xml file from CatDV worker node\n\n";
	print "example debug usage:  catdv-xml.pl debug /path/to/catdv.xml\n\n";
	exit	
}


$xml = new XML::Simple;

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

our %metadata = ();
require "metadata.conf";

# echo output back to PresSTORE.  Simply add each of your key/value pairs to the next line.
# Don't forget to escape the curly braces for the values.
if($ARGV[2] eq 'dump'){
	print Dumper($data);
} else {
    while ( my ($key, $value) = each(%metadata) ) {
        print "$key \{$value\} ";
    }
    print "\n";
}