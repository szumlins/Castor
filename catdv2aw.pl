#!/usr/bin/perl
###########################################################################################################
# This script writes file paths into a temp queue file for aw-queue.pl to poll for archive/restore        #
# Written by Mike Szumlinski																			  #
# szumlins@mac.com																						  #
# November, 2010																						  #
#																										  #	
# Special thanks to André Aulich for the paradigm used in this script									  #
###########################################################################################################

#############################
# Known Issues/Future Plans #
#############################
# Does not validate entry into queue file.  This requires knowing method as restore file paths are
# not online and cannot be verified.  Plans to include this in the future that will require an additional
# variable.

##################
# User variables #
##################

# are we writing to the archive or restore path?
$queue_file = $ARGV[0];

# the full file path to archive/restore
$file = $ARGV[1];

#validate input from the cli

if ($ARGV[0] eq '' || $ARGV[1] eq ''){
	print "\nusage: catdv2aw.pl queue_file file_path\n\n";
	print "queue_file: full path to queue file\n";
	print "file_path: path of file getting added to PresSTORE Archive or Restore queue\n\n";
	exit
}

#does our queue file exist?

if(-e $queue_file){
	open QUEUE, ">>", $queue_file or die $!; 
} else {
	print "Cannot find queue file $queue_file";
}



print QUEUE "$file\n";