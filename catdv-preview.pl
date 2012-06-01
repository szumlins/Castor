#!/usr/bin/perl

# this script assumes path based previews in CatDV.
# this script also assumes all paths are written into the full path of their source:
# example - preview for /Volumes/XSan/MyMovie.mov would be written to /Path/To/Previews/Volumes/Xsan/MyMovie.previewextension


# set up our perl environment

use File::Basename;
use File::Copy;
use Sys::Syslog;

openlog($0,'','user');

require "/usr/local/Castor/conf/catdv.conf";

if ($ARGV[0] eq ''){
	print "\nusage: catdv-preview.pl video_file \n\n";
	print "video_file: the full path of the original media location\n\t (ex. \"/path/to/MyVideo.mov\")\n\n";
	exit	
}

# use File::Basename to split up and reformat our string

my $fullpath = $ARGV[0];
my ($name,$path,$suffix) = fileparse($fullpath, qr/\.[^.]*/);

#compile our full path to our proxy

$previewloc = "$previewdir$path$name$previewextension";

syslog('err',"Looking for file \@$previewloc");

if(-e $previewloc){
	syslog('err',"Proxy for $ARGV[0] found at $previewloc");
	# if we have a proxy, move it to our temp location
	
	$awproxyloc = "$awproxypath/$name$previewextension";
	
	copy($previewloc,$awproxyloc) or die "Copy failed: $!";
	
	if(-e $awproxyloc){
		syslog('err',"$name$previewextension copied to $awproxypath successfully");
	} else {
		syslog('err',"$name$previewextension did not get copied to $awproxypath");
	}
	
} else {
	syslog('err',"No proxy found for $ARGV[0].  Skipping.");
	
	# if we can't find the movie, we could generate a proxy or set $awproxyloc to a fixed slate for no preview
	# here we would call our standard proxy generation script - see my qt_tools example for more info	
}

print $awproxyloc;
closelog;
