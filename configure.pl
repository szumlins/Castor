#!/usr/bin/perl

use warnings;

sub isint{
	my $val = shift;
	return ($val =~ m/^\d+$/);
}

sub run_config{
	$usertest = `whoami`;
	$usertest =~ s/\n//;
	
	if($usertest ne "root"){
		print "\nThis script must be run as root.  Try sudo ./configure.pl\n\n";
		exit;
	}
	
	print "\nWelcome to the Castor configurator.  We will ask a few questions to get\n"; 
	print "your environment set up. Anything contained in [] is the default.  Simply\n";
	print "hitting enter will set it as default.\n\n";
	
	print "Username you use to log in to PresSTORE []: ";
	$username = <>;
	print "Password for this user []: ";
	$password = <>;
	print "Port the PresSTORE socket is running on [9001]: ";
	$port = <>;
	print "Location of for temporary CatDV XML files [/usr/local/Castor/tmp]: ";
	$xmldir = <>;
	print "Location of CatDV Proxy Movie Root []: ";
	$previewdir = <>;
	print "Type of previews are we making (.mp4,.mov,.m4v,.mpg) [.mp4]: ";
	$previewextension = <>;
	print "Temporary preview storage location [/tmp]: ";
	$awproxypath = <>;
	print "PresSTORE Archive Plan Number [10001]: ";
	$archiveplan = <>;	
	print "PresSTORE Archive Index [Default-Archive]: ";
	$archiveindex = <>;		
	print "Time of day to do batch archive (24hr clock, 0-23) [2]: ";
	$archivetime = <>;		
	print "Frequency to check restore queue and run batch (minutes) [10]: ";
	$restorefrequency = <>;			
	print "\n\n";
	
	$hostname = `/usr/local/aw/bin/nsdchat -c srvinfo hostname`;
	$hostname =~ s/\n//;
	$archiveplan =~ s/\n//;
	$archiveindex =~ s/\n//;
	$archivetime =~ s/\n//;
	$restorefrequency =~ s/\n//;
	
	$i=0;
	
	if($hostname eq ''){
		print "Error: nsdchat could not look up hostname.  Is PresSTORE running?\n";
		$i++;
	}
	
	$username =~ s/\n//;
	$password =~ s/\n//;
	
	if($username eq '' || $password eq ''){
		print "Error: username or password left blank.\n";
		$i++;
	}
	
	$port =~ s/\n//;
	
	if($port eq ''){
		$port = "9001";
	}
	
	$xmldir =~ s/\n//;
	
	if($xmldir eq ''){
		$xmldir = "/usr/local/Castor/tmp";
		unless(-e $xmldir){
			print "Error: XML Directory not found";
			$i++;
		}
	}
	
	$previewdir =~ s/\n//;
	
	unless(-e $previewdir){
		print "Error: CatDV Preview Directory not found.\n";
		$i++;
	}
	
	$previewextension =~ s/\n//;
	
	if($previewextension eq ''){
		$previewextension = ".mp4";
	}
	
	$awproxypath =~ s/\n//;
	
	if($awproxypath eq ''){
		$awproxypath = "/tmp";
	}
	if($archiveplan eq ''){
		$archiveplan = "10001";
	}
	$testplan = `/usr/local/aw/bin/nsdchat -c ArchivePlan names | grep $archiveplan`;
	
	if($testplan eq ''){
		print "Error: could not find archive plan $archiveplan.  Please doublecheck.\n";
		$i++;
	}
	
	if($archiveindex eq ''){
		$archiveindex = "Default-Archive";
	}
	$testindex = `/usr/local/aw/bin/nsdchat -c ArchiveIndex names | grep $archiveindex`;
	
	if($testindex eq ''){
		print "Error: could not find archive index $archiveindex.  Please doublecheck.\n";
		$i++;
	}
	
	if($archivetime eq ''){
		$archivetime = 2;
	}
	
	if(isint($archivetime)){
		if($archivetime < 0 || $archivetime > 23){
			print "Error: $archivetime:00 doesn't seem to be a valid time\n";
			$i++;
		}
	} else {
		print "Error: $archivetime:00 isn't a time I've ever heard of.  Try again.\n";
		$i++;
	}

	if($restorefrequency eq ''){
		$restorefrequency = 10;
	}

	if(isint($restorefrequency)){
		$original = $restorefrequency;
		$restorefrequency = $restorefrequency*60;
	} else {
		print "Error: $restorefrequency doesn't seem to be a valid unit of time.\n";
		$i++;
	}		
	if($i>0){
		print "Multiple errors found, please double check your settings and retry\n\n";
		exit;
	} else {
		summary();
	}
}

sub summary{
	print "\n\n";
	print "Summary\n";
	print "----------------------------------\n";
	print "Hostname: $hostname\n";
	print "Username: $username\n";
	print "Password: $password\n";
	print "PresSTORE Socket Port: $port\n";
	print "XML location: $xmldir\n";
	print "CatDV Preview Root: $previewdir\n";
	print "Preview Type: $previewextension\n";
	print "Temp Proxy Storage Location: $awproxypath\n";
	print "Archive Plan: $archiveplan\n";
	print "Archive Index: $archiveindex\n";
	print "Archive Schedule: $archivetime:00\n";
	print "Restore Frequency: $original minutes\n\n";
	print "Write config to file?\nWARNING! This WILL overwrite your existing config files [y/n]: ";

	$submit = <>;
	$submit =~ s/\n//;	

	validate($submit);
}

sub validate{

	if($_[0] eq "y"){
		print "\nWriting aw-queue.conf file\n";
		write_awconf();
		print "Writing catdv.conf file\n";
		write_catdvconf();
		print "Creating LaunchDaemon plists\n";
		write_launchd();
		print "Setting up queue files and permissions\n";
		`/usr/bin/touch /usr/local/Castor/queues/archive-queue.txt`;
		`/usr/bin/touch /usr/local/Castor/queues/restore-queue.txt`;		
		`/usr/bin/touch /Library/Logs/aw-queue.log`;
		`/usr/bin/touch /Library/Logs/aw-queue-err.log`;
		`/bin/chmod 777 /usr/local/Castor/queues/archive-queue.txt`;
		`/bin/chmod 777 /usr/local/Castor/queues/restore-queue.txt`;
		`/bin/chmod 775 /Library/Logs/aw-queue.log`;
		`/bin/chmod 775 /Library/Logs/aw-queue-err.log`;
		print "\n";
		print "You will now need to edit\n\n/usr/local/Castor/conf/metadata.conf\n\nby hand to complete the install\n\n";
	} elsif($_[0] eq "n"){
		print "Aborting config. Nothing has been written to disk.\n";
	} else {
		print "\nI don't understand $submit";
		undef($_[0]);
		summary();
	}	
	
}

sub write_awconf{
	open AWCONF, ">", "/usr/local/Castor/conf/aw-queue.conf" or die $!;
	
	print AWCONF "##################\n";
	print AWCONF "# User variables #\n";
	print AWCONF "##################\n";
	print AWCONF "\n";
	print AWCONF "# Hostname of the PresSTORE server.  Find out by running \"/usr/local/aw/bin/nsdchat -c srvinfo hostname\" on the server\n";
	print AWCONF "\n";
	print AWCONF "\$hostname = \"$hostname\"\;\n";	
	print AWCONF "\n";
	print AWCONF "# Username of a user on the PresSTORE server with permissions to archive and restore.\n";
	print AWCONF "\n";
	print AWCONF "\$username = \"$username\"\;\n";
	print AWCONF "\n";
	print AWCONF "# Password of a user on the PresSTORE server with permissions to archive and restore.\n";
	print AWCONF "\n";	
	print AWCONF "\$password = \"$password\"\;\n";
	print AWCONF "\n";	
	print AWCONF "# Default nsdchat port is 9001.  Do not change unless you specifically changed this in your PresSTORE server config\n";
	print AWCONF "\n";
	print AWCONF "\$port = \"9001\"\;";
	
	close AWCONF;
}

sub write_catdvconf{
	open CDVCONF, ">", "/usr/local/Castor/conf/catdv.conf" or die $!;
	
	print CDVCONF "###################\n";
	print CDVCONF "# User Variables  #\n";
	print CDVCONF "###################\n";
	print CDVCONF "\n";
	print CDVCONF "# Location of xml files being written by worker node.  Default is /usr/local/Castor/tmp\n";
	print CDVCONF "\n";
	print CDVCONF "\$xmldir = \"$xmldir\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Location of CatDV Preview Files root\n";
	print CDVCONF "\n";
	print CDVCONF "\$previewdir = \"$previewdir\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Type of previews being generated in CatDV (mov, mp4, m4v, mpg, etc)\n";
	print CDVCONF "\n";
	print CDVCONF "\$previewextension = \"$previewextension\"\;\n";
	print CDVCONF "\n";
	print CDVCONF "# Temporary preview location\n";		
	print CDVCONF "\n";
	print CDVCONF "\$awproxypath = \"$awproxypath\"\;\n";	
	
	close CDVCONF;
}

sub write_launchd{
	#make sure they aren't running already
	
	if(-e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" && -e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist"){
		print "Trying to stop LaunchDaemons\n";
		`/bin/launchctl unload -w /Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist`;
		`/bin/launchctl unload -w /Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist`;	
	} else {
		print "Launchd plist files don't exist yet, no need to stop\n";
	}
	
	#open the files for writing
	print "Trying to open plist files\n";
	
	open ALD, ">", "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" or die $!;
	open RLD, ">", "/Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist" or die $!;
	
	#first do the archive plist
	
	print "Writing Archive plist\n";
	
	print ALD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print ALD "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n";
	print ALD "<plist version=\"1.0\">\n";
	print ALD "<dict>\n";
	print ALD "	<key>Disabled</key>\n";
	print ALD "	<false/>\n";
	print ALD "	<key>Label</key>\n";
	print ALD "	<string>org.provideotech.aw-queue-archive</string>\n";
	print ALD "	<key>ProgramArguments</key>\n";
	print ALD "	<array>\n";
	print ALD "		<string>/usr/local/Castor/aw-queue.pl</string>\n";
	print ALD "		<string>/usr/local/Castor/queues/archive-queue.txt</string>\n";
	print ALD "		<string>archive</string>\n";
	print ALD "		<string>$archiveplan</string>\n";
	print ALD "	</array>\n";
	print ALD "	<key>StartCalendarInterval</key>\n";
	print ALD "	<dict>\n";
	print ALD "		<key>Hour</key>\n";
	print ALD "		<integer>$archivetime</integer>\n";
	print ALD "	</dict>\n";
	print ALD "</dict>\n";
	print ALD "</plist>\n";
	
	#next do the restore plist
	
	print "Writing Restore plist\n";	
	
	print RLD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
	print RLD "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n";
	print RLD "<plist version=\"1.0\">\n";
	print RLD "<dict>\n";
	print RLD "	<key>Disabled</key>\n";
	print RLD "	<false/>\n";
	print RLD "	<key>Label</key>\n";
	print RLD "	<string>org.provideotech.aw-queue-restore</string>\n";
	print RLD "	<key>ProgramArguments</key>\n";
	print RLD "	<array>\n";
	print RLD "		<string>/usr/local/Castor/aw-queue.pl</string>\n";
	print RLD "		<string>/usr/local/Castor/queues/restore-queue.txt</string>\n";
	print RLD "		<string>restore</string>\n";
	print RLD "		<string>$archiveplan</string>\n";
	print RLD "		<string>$archiveindex</string>\n";	
	print RLD "	</array>\n";
	print RLD "	<key>StartInterval</key>\n";
	print RLD "	<integer>$restorefrequency</integer>\n";
	print RLD "</dict>\n";
	print RLD "</plist>\n";

	#close the files
	
	close ALD;
	close RLD;
	
	#set up proper permissions
	
	print "Setting proper launchd permissions\n";
	
	if(-e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist" && -e "/Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist"){
		`/usr/sbin/chown root:wheel /Library/LaunchDaemons/org.provideotech.aw-queue*`;
		`/bin/chmod 644 /Library/LaunchDaemons/org.provideotech.aw-queue*`;
	} else {
		print "Error: Could not locate launchd plists.  Please verify by hand\n";
	}

	#start up
	
	print "Trying to start newly created LaunchDaemons\n";
	
	`/bin/launchctl load -wF /Library/LaunchDaemons/org.provideotech.aw-queue-archive.plist`;
	`/bin/launchctl load -wF /Library/LaunchDaemons/org.provideotech.aw-queue-restore.plist`;	
}

run_config();