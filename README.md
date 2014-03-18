ServiceNow
==========

ServiceNow Integration

Perl is a tool that is commonly available to system admins.  Since ServiceNow is a hosted service and there are
many uses for extracting server CMDB data, these scripts enable web service queries to the platform.

ServiceNow's web service will only return a maximum of 250 results.  The snQuery.pl script will extract the
total number of keys (records) in the CMDB and then divide the total into batches.

Requirements (Perl Modules)
  -SOAP::Lite
  -Term::ReadKey
  
Configuration (config.txt)

Edit to include your ServiceNow instance
  instance:<your_instance_name>

Edit to include your ServiceNow user ID
  sn_user:<your_username>

Running (snQuery.pl)
The script is designed to be run manually and will prompt for a password.  The output can be modified to print
in any necessary format.  If additional parameters are needed, access your ServiceNow CMDB instance 
WSDL at: http://<your_instance_url>/cmdb_ci_server.do?WSDL
