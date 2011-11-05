#!/usr/bin/perl -w

use LWP::UserAgent;
use DBI;
use DBD::mysql;

$sock_location = '/var/lib/mysql/mysql.sock';
&checkingsites();

sub sitechecker {
	my (@sites) = @_;
	my %siteerror = ();
	foreach $site (@sites) {
		
		$ua = new LWP::UserAgent;
		$req = new HTTP::Request 'GET' ,"$site";
		$res = $ua->request($req);
		$ts = localtime;
		$status = $res->status_line;
		if ($res->is_success) {
			&logger($ts, "$site returned status: $status");
		} else {
			$siteerror{ $site } = $ts;
			&logger($ts, "$site returned status: $status");
		}
		
	}
	if (%siteerror) {
		&mailer(%siteerror);
	}
}

sub logger {

	my ($ts, $message) = @_;
	my $logfile = '/var/log/webcheck';
	open( LOGFILE, ">>$logfile") or die "Here's what happened: $! \n";
	print LOGFILE "$ts $message\n";
	close LOGFILE;
}

sub getsites {
	$dbh = &connect_db();
	$statement = "SELECT weburl FROM websites";

	$sth = $dbh->prepare($statement);
	$sth->execute;
	while (@row_ary = $sth->fetchrow_array) {
		foreach (@row_ary) {
			push( @sites, $_);
		}
	}

	$sth->finish;

	#disconnect db

	$dbh->disconnect or warn "Disconnection error: $DBI::errstr\n";
	return @sites;
}

sub mailer {
	# This is where an e-mail message will be sent 
	my (%websites) = @_;
	$sendmail = '/usr/sbin/sendmail -t';
	$recipient = '<RECIPIENT_EMAIL>';
	$sender = '<SENDER_EMAIL>';
	open( MAIL, "|$sendmail");
	
	print MAIL "From: $sender\n";
	print MAIL "To: $recipient\n";
	print MAIL "Subject: Error on the Websites\n";
	foreach $sitename ( keys(%websites) ) {
		print MAIL "There was an issue on " .  $sitename . " at " . $websites{$sitename} . "\n";
	}
	close MAIL;
	
	print "E-mail sent to $recipient\n";
}

sub connect_db {
	$db = '<DB_NAME>';
	$host = "<DB_HOST>";
	$user = '<DB_USER>';
	$password = '<DB_PASSWORD>';
	
	#connect to DB
	my $connect_dbh = DBI->connect("DBI:mysql:database=$db:host=$host:mysql_socket=$sock_location", $user, $password)
						or die "Can't connect to databases: $DBI::errstr\n";
	return $connect_dbh;
}

sub checkingsites {
	$checktime = time() + 300;
	
	@sitelist = &getsites();

	while ($checktime > time()) {
		&sitechecker(@sitelist);
		sleep 15;
	}
	&checkingsites();
}
