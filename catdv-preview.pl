#!/usr/bin/perl

# this script assumes path based previews in CatDV.
# this script also assumes all paths are written into the full path of their source:
# example - preview for /Volumes/XSan/MyMovie.mov would be written to /Path/To/Previews/Volumes/Xsan/MyMovie.previewextension


# set up our perl environment

use File::Basename;
use File::Copy;

# where are our previews?

$previewdir = "/Users/Shared/CatDV Docs/Proxies";

# what kind of previews are we making?  (mov, mp4, m4v, etc)

$previewextension = "mp4";

# where do we want to temporarily copy the previews to before adding to AW index?

$awproxypath = "/tmp";

# use File::Basename to split up and reformat our string

my $fullpath = $ARGV[0];
my ($name,$path,$suffix) = fileparse($fullpath, qr/\.[^.]*/);

#compile our full path to our proxy

$previewloc = "$previewdir$path$name.$previewextension";

if(-e $previewloc){

	# if we have a proxy, move it to our temp location
	
	$awproxyloc = "$awproxypath/$name.$previewextension";
	
	`cp \"$previewloc\" \"$awproxyloc\"`;
	
	} else {
	
	# if we can't find the movie, generate a proxy
	
	# here we would call our standard proxy generation script - see my qt_tools example for more info
	
	$awproxyloc = $generatedproxyloc;
}

print $awproxyloc;
