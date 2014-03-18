#!/usr/bin/perl

# -------------------------------------------
# snQuery.pl
# Tim Pilson
# 3/18/2014
# 
# Manually query servers from ServiceNow CMDB
# -------------------------------------------

use strict;
use SOAP::Lite;
use Term::ReadKey;

## Required config file
my($instance,$sn_user);
open(my $config, "<", "config.txt") || die "ERROR: can't open config file\n";
while (<$config>) {
  chomp;
  next if ( /^\#/ );
  my($key,$value) = split(/:/);
  if ( $key eq "instance" ) { $instance = $value }
  if ( $key eq "sn_user" )  { $sn_user  = $value }
}

## Check config parameters
if (( $sn_user eq "" ) || ( $instance eq "" )) {
  print "ERROR: missing config parameters\n";
  exit 1;
}

## Get Credentials for Authentication
print "Enter Password: ";
ReadMode('noecho'); ## turn off echo for grabbing password
chomp(my $password = <STDIN>);
ReadMode(0);
print "\n";

## SOAP basic auth
sub SOAP::Transport::HTTP::Client::get_basic_credentials {
   return "$sn_user" => "$password";
}

## SOAP specify the endpoint to connect
my $soap = SOAP::Lite
    ->proxy("https://$instance/cmdb_ci_server.do?SOAP");

## Get total number of records first
##   Since ServiceNow's web services will only return a
##   a total of 250 records, this "windowing" method will
##   batch the queries to get the full result set.
## ------------------------------------------------------
my $method = SOAP::Data->name('getKeys')
    ->attr({xmlns => 'http://www.service-now.com/'});

## Query parameter
push(my @params, SOAP::Data->name("operational_status" => "1") );

## Get results, divide into array
my $result     = $soap->call($method => @params)->result;
my @serverKeys = split(",", $result);
my $totalCount = @serverKeys;

## Re-establish connection, use windowing to get all records
my $windowSize = 100; ## Max 250
my $lastRow    = 0;   ## initialize
my $count      = 0;   ## initialize

## Loop through results, offset query start row to get windowing
for ( my $i = 0; ($lastRow +1) < $totalCount; $i += ($windowSize) ) {
  $lastRow = ($i + $windowSize);

  print "Querying rows: $i \- $lastRow\n\n";

  my $soap = SOAP::Lite
      -> proxy('https://southwestdev.service-now.com/cmdb_ci_server.do?displayvalue=true&SOAP');

  my $method = SOAP::Data->name("getRecords")->
      attr({xmlns => "http://www.service-now.com/"});

  my @params = (SOAP::Data->name("operational_status" => "1"));

  ## Starting offset of records (windowing)
  push(@params, SOAP::Data->name(__first_row => "$i") );

  ## Determine last row
  ## Query fails if __last_row is greater than total records
  ## __last_row is not inclusive of the last row.
  if ( $lastRow > $totalCount ) {
    push(@params, SOAP::Data->name(__last_row => "$totalCount") );
  } else {
    push(@params, SOAP::Data->name(__last_row => "$lastRow") );
  }

  my $result = $soap->call($method => @params);

  print_fault($result);

  my @serverData = @{$result->body->{getRecordsResponse}->{getRecordsResult}};

  ## Loop through results
  ##   Use this section for determining which results
  ##   are needed.
  ## ------------------------------------------------
  foreach my $serverRec (@serverData) {
    print "$serverRec->{name}\n";
    print "           model_id: $serverRec->{model_id}\n";
    print "      serial_number: $serverRec->{serial_number}\n";
    print "                 os: $serverRec->{os}\n";
    print "         os_version: $serverRec->{os_version}\n";
    print "    os_service_pack: $serverRec->{os_service_pack}\n";
    print "  short_description: $serverRec->{short_description}\n";
    print "    hardware_status: $serverRec->{hardware_status}\n";
    print "   first_discovered: $serverRec->{first_discovered}\n";
    print "     sys_class_name: $serverRec->{sys_class_name}\n";
    print "           used_for: $serverRec->{used_for}\n\n";
  }
}

sub print_fault {
  my ($result) = @_;

  if ($result->fault) {
    print "faultcode: " . $result->fault->{'faultcode'} . "\n";
    print "faultstring: " . $result->fault->{'faultstring'} . "\n";
    print "detail: " . $result->fault->{'detail'} . "\n";
  }
}
