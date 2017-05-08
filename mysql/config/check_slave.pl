#!/usr/bin/perl -w

use DBI;

use DBD::mysql;


# CONFIG VARIABLES

$SBM = 120;

$db = "test";

$host = $ARGV[0];

$port = 3306;

$user = "root";

$pw = "zzyhappy";

# SQL query

$query = "show slave status";

$dbh = DBI->connect("DBI:mysql:$db:$host:$port", $user, $pw, { RaiseError => 0,PrintError => 0 });

if (!defined($dbh)) {
#print"1";
exit 1;

}

$sqlQuery = $dbh->prepare($query);

$sqlQuery->execute;

$Slave_IO_Running =  "";

$Slave_SQL_Running = "";

$Seconds_Behind_Master = "";

while (my $ref = $sqlQuery->fetchrow_hashref()) {

$Slave_IO_Running = $ref->{'Slave_IO_Running'};

$Slave_SQL_Running = $ref->{'Slave_SQL_Running'};

$Seconds_Behind_Master = $ref->{'Seconds_Behind_Master'};

}

$sqlQuery->finish;

$dbh->disconnect();

if ( $Slave_IO_Running eq "No" || $Slave_SQL_Running eq "No" ) {

#print"1";
exit 1;

} else {

if ( $Seconds_Behind_Master > $SBM ) {
#print"1";
exit 1;

} else {
#print"0";
exit 0;

}

}
