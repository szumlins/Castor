#!/usr/bin/perl
###########################################################################################################
# This script allows for any application to pass a queue of files to be restored or archived to PresSTORE #
# Written by Mike Szumlinski																			  #
# szumlins@mac.com																						  #
# January 21, 2012																						  #
#																										  #	
# Special thanks to André Aulich for the paradigm used in this script									  #
###########################################################################################################

#############################
# Known Issues/Future Plans #
#############################
#
# Does not validate that files being restored have been removed from the archive queue - will cause 
# issues if a file is requested for restore before the chosen archive interval is run
#


################
# Begin Script #
################

#set up to allow basic errors to flow to syslog

use Sys::Syslog;
openlog($0,'','user');

#grab our variables from our conf file;

require "/usr/local/Castor/conf/aw-queue.conf";

#this is the path for the original media queue to be archived/restored
$full_queue_path = $ARGV[0];

#this is the method being used (archive or restore)
$method = $ARGV[1];

#generate a uique session ID based on the date
$sessionid=`date | md5`;
$sessionid=~ s/\n//;

#this is the path to nsdchat.  You need to change this if you do not have a standard PresSTORE install
$nsdchat = "/usr/local/aw/bin/nsdchat -s awsock:/$username:$password:$sessionid\@$hostname:$port -c";

#if the filesystem for the archived content lives on a different PresSTORE client than localhost, change that here
$client = "localhost";

#index ID - this is passed as the third argument to the CLI
$index = $ARGV[3];

#log file location.  Change this if you want this going someplace different.  Must change on non-MacOS X systems
$logfile = "/Library/Logs/aw-queue.log";

#error log file location.  This simply lists the date stamp, the method, and the files that weren't able to be archived/restored
$errfile = "/Library/Logs/aw-queue-err.log";

#make sure the input is good

#if cli variables are empty, print usage to user/log

if ($ARGV[0] eq '' || $ARGV[1] eq '' || $ARGV[2] eq ''){
	print "\nusage: aw-queue.pl queue_file archive|restore archive_plan archive_index\n\n";
	print "queue_file: full path to queue file.\n";
	print "archive|restore: select whether to archive or restore from archive the source_file.\n";
	print "archive_plan: which archive plan you want PresSTORE to use.\n";
	print "archive_index: only necessary for restore, this is the PresSTORE index we will look up our files from.\n\n";
	exit
}

#if method is not proper, inform user

if ($ARGV[1] ne 'archive' && $ARGV[1] ne 'restore'){
	print "\nMethod \"$ARGV[1]\" not defined.  Please choose \"archive\" or \"restore\"\n\n";
	syslog('err',"Method \"$ARGV[1]\" not defined.  Please choose \"archive\" or \"restore\"");
	exit
}

#try a simple login to the server to validate nsdchat
$testlogin = `$nsdchat srvinfo hostname`;
$testlogin =~ s/\n//;
if ($testlogin ne $hostname){
	$date = `date`;
	$date =~ s/\n//;
	print "\nCould not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.\n";	
	syslog('err',"Could not connect to PresSTORE socket using \"$nsdchat\".  Please verify variables.");
	exit		
}

#check that the archive plan chosen is valid and enabled

if ($ARGV[2] eq ''){
	print "\narchive_plan not defined\n\n";
} else {
	$plan_check = `$nsdchat ArchivePlan $ARGV[2] enabled`;
	if($plan_check == '0'){
		print "\nArchive plan \"$ARGV[2]\" disabled.  Please enable plan\n\n";
		syslog('err',"Archive plan \"$ARGV[2]\" disabled.  Please enable plan");
		exit
	}
	if($plan_check != '1'){
		print "\nArchive plan \"$ARGV[2]\" not found.\n\n";
		syslog('err',"Archive plan \"$ARGV[2]\" not found.");
		exit
	}
}

#close the syslog, since we have a good working environment we can start logging to our own log

closelog;

# Now that we know we have all the information we need, lets open our log file for writing in case there are errors in the process
# if the log file doesn't exist, we create it, otherwise we append
#
# In MacOS X 10.7, the /Library/Logs directory is now not world writeable as in previous versions of the OS.  This means you will have to
# initialize and allow the user that runs this script access to write to your log file at /Library/Logs/aw-queue.log if you would like to 
# use the default location.

# Initiate our log file
if(-e $logfile){
	open LOGFILE, ">>", $logfile or die $!;
} else {
	open LOGFILE, ">", $logfile or die $!;
}

if(-e $errfile){
	open ERRFILE, ">>", $errfile or die $!;
} else {
	open ERRFILE, ">", $errfile or die $!;
}


#check to see if our queue file is actually there.  if it isn't, print to the log and quit.
if(! -e $full_queue_path){
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Queue file \"$full_queue_path\" does not exist! Exiting script, please check your queue file.\n";	
	exit
}

if(! -s $full_queue_path){
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Queue file \"$full_queue_path\" is empty. Nothing to do\n";	
	exit
}

#lets get rid of duplicates in our input file so we don't end up with unecessary tape work or errors

my $stripped = $full_queue_path;
my %seen = ();
{
	local @ARGV = ($stripped);
	local $^I = '.bac';
	while (<>){
		$seen{$_}++;
		next if $seen{$_} > 1;
		print;
	}
}


#run archive method
if($method eq 'archive'){
	#create job
	$archive_selection = `$nsdchat ArchiveSelection create $client $ARGV[2]`;
	$archive_selection =~ s/\n//;		
	if($archive_selection eq ''){

		#find out why we failed
		$geterr = `$nsdchat geterror`;
		$geterr =~ s/\n//;

		#print it to the log
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- Archive Selection not created.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
		exit;		
	}
	
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Archive selection $archive_selection created successfully\n";
	
	#open queue file, add each file to archive queue
	open FILE, "<",$full_queue_path or die $!;

	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Archive queue file $full_queue_path successfully opened\n";

	$i = 0;
	$j = 0;
	while (<FILE>){
		#these regexps attempt to escape non-standard characters in file names
		$_ =~ s/\n//;
		$_ =~ s/'/\'/g;
		$_ =~ s/\#/\\#/g;
		$_ =~ s/\(/\\(/g;
		$_ =~ s/\)/\\)/g;
		$_ =~ s/"/\"/g;
		$_ =~ s/\&/\\&/g;
		$_ =~ s/\,/\\,/g;
		@handles[$i] = `$nsdchat ArchiveSelection $archive_selection addentry {"$_"}`;		
		if (length(@handles[$i])<2){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		
		
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- File $_ did not generate archive handle and will not be archived.  PresSTORE returned \"$geterr\".\n";	
			
			print ERRFILE "$date -- {$method} - $_\n";
			
			$j++;
		} else {
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- File $_ generated archive handle @handles[$i]";		
		}
		
		$i++;
	}
		
	$date = `date`;
	$date =~ s/\n//;
	$filescount = $i-$j;
	print LOGFILE "$date -- Preparing $filescount files for archive\n";		
	
	if($filescount<=0){
		#don't submit a 0 job file
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- 0 valid archive handles generated. Exiting.\n\n";		
	} else {
		#submit archive job to run
		$job_id = `$nsdchat ArchiveSelection $archive_selection submit yes`;
		$job_id =~ s/\n//;		
		
		if($job_id eq ''){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		
		
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- Job not submitted. PresSTORE returned error \"$geterr\". Exiting.\n\n";		
			exit;
		}
	}
	
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Archive job $job_id successfully submitted\n";

	#if job finished cleanly, lets clean out that file
	
	open FILE,">",$full_queue_path;
	close FILE;
	
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Archive queue emptied\n";

}

#run restore method
if($method eq 'restore'){
	#verify we have a good index
	$goodindex = `$nsdchat ArchiveIndex names | grep $index`;
	if($goodindex eq ''){
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- Could not find Archive Index \"$index\", exiting.  Please check the \$index variable in aw-queue.pl\n\n";
		exit;
	}
	
	#create job
	$restore_selection = `$nsdchat RestoreSelection create $client`;
	$restore_selection =~ s/\n//;
	if($restore_selection eq ''){

		#find out why we failed
		$geterr = `$nsdchat geterror`;
		$geterr =~ s/\n//;

		#print it to the log
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- Restore Selection not created.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
		exit;		
	}


	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Restore selection \"$restore_selection\" created successfully\n";

	
	#open queue file, add each file to restore queue
	open FILE, "<",$full_queue_path or die $!;

	$i = 0;
	$j = 0;
	
	while (<FILE>){	
		
		$_ =~ s/\n//;
		$_ =~ s/'/\'/g;
		$_ =~ s/\#/\\#/g;
		$_ =~ s/\(/\\(/g;
		$_ =~ s/\)/\\)/g;
		$_ =~ s/"/\"/g;
		$_ =~ s/\&/\\&/g;
		$_ =~ s/\,/\\,/g;
		
		if (defined($_)){
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- Looking up archive handle for file \"$_\" in index \"$index\"\n";
			@archive_handles[$i] = `$nsdchat ArchiveEntry handle $client {"$_"} $index`;	
			chomp(@archive_handles[$i]);
			
			if (length(@archive_handles[$i])<2){
				$geterr = `$nsdchat geterror`;
				$geterr =~ s/\n//;
				
				$date = `date`;
				$date =~ s/\n//;
				print LOGFILE "$date -- Archive handle could not be looked up.  PresSTORE returned error \"$geterr\".\n";
				print ERRFILE "$date -- {$method} - $_\n";	
				push(@restore_handles,"err");
				$j++;
			} else {
				@restore_handles[$i] = `$nsdchat RestoreSelection $restore_selection addentry {@archive_handles[$i]}`;
				chomp(@restore_handles[$i]);
				
				if (length(@restore_handles[$i])<2){
					$geterr = `$nsdchat geterror`;
					$geterr =~ s/\n//;
					
					$date = `date`;
					$date =~ s/\n//;
					print LOGFILE "$date -- Restore handle could not be looked up.  PresSTORE returned error \"$geterr\". Exiting.\n\n";
					print ERRFILE "$date -- {$method} - $_\n";	
					
					$j++;				
				} else {			
					$date = `date`;
					$date =~ s/\n//;
					print LOGFILE "$date -- Archive Handle @archive_handles[$i] generated restore handle \"@restore_handles[$i]\" successfully\n";
				}
			}		
		$i++;
		}
	}
	
	$date = `date`;
	$date =~ s/\n//;
	$filecount = $i-$j;
	print LOGFILE "$date -- Preparing $filecount files for restore\n";		

	if($filecount<=0){
		open FILE,">",$full_queue_path;
		close FILE;		
		
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- Restore queue emptied\n";
		
		#don't submit a 0 job file
		$date = `date`;
		$date =~ s/\n//;
		print LOGFILE "$date -- 0 valid restore handles generated. Exiting.\n\n";
	
		exit;
	} else {
		#submit restore job to run
		$job_id = `$nsdchat RestoreSelection $restore_selection submit`;
		$job_id =~ s/\n//;		
		
		if($job_id eq ''){
			$geterr = `$nsdchat geterror`;
			$geterr =~ s/\n//;		
		
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- Job not submitted. PresSTORE returned error \"$geterr\". Exiting\n\n";		
			exit;
		} else {	
			$date = `date`;
			$date =~ s/\n//;
			print LOGFILE "$date -- Restore job $job_id successfully submitted\n";	
		}
	}
	
	open FILE,">",$full_queue_path;
	close FILE;
	
	$date = `date`;
	$date =~ s/\n//;
	print LOGFILE "$date -- Restore queue emptied\n";
	
}

$date = `date`;
$date =~ s/\n//;
print LOGFILE "$date -- Script Finished Cleanly\n\n";

close LOGFILE;
