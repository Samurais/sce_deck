####################################################################
#
# Perl Health Check Script for Microsoft Windows NT/2000/XP/2003
#
# $Header: /home/cvs/ntcheck/2c4nt.pl,v 1.242 2008/09/15 16:04:00 matthewg Exp $
#
# Authors: Various individuals across IBM Software Group, including:
#
#          Matthew Glogowski (matthew_glogowski@us.ibm.com)
#          Ross Combs
#          Greg Pflaum
#          Jeff Mitchell
#          Wes McCallister
#          (and possibly others)
#
#          Some routines in this script were derived from
#          Microsoft's Script-o-matic Version 2.0 tool.  These routines
#          are WMI routines which have been converted to Perl.
#          Please see: http://www.microsoft.com/technet/scriptcenter/default.mspx
#
# This tool is not certified, approved, or maintained by NCSS/GSDS.
# THERE IS NO WARRANTY OF ANY KIND.
#
#
# NOTE:   For support and any other general question(s) please
#         direct all queries to:
#
#         matthew_glogowski@us.ibm.com
#
####################################################################

####################################################################
#
# Required Modules
#
#
#
#
#
#
####################################################################

use strict;

# FIXME: convert some of these to requires
use Config;                  # figuring out where we're running
use Cwd;                     # a 'safe' cwd/pwd for perl
use Date::Calc qw(:all);
use File::Stat;
use File::Find;              # used for finding certain filenames and types
use Getopt::Long;            # command line option support
use Net::Ping;               # for ping tests
use Net::Domain qw(hostname hostfqdn hostdomain);
#use POSIX qw(strftime);      # FIXME: I do not see us using strftime anywhere
use Clone qw(clone);         # for hash copy
use Sys::Hostname;           # used for getting the hostname and other info
use Time::local;
use Tk;                      # GUI modules
use Tk::CheckButton;
use Tk::RadioButton;
use Tk::ROText;
use Win32;
use Win32::AdminMisc;        # for GetError GetFileInfo GetLogonName GetProcessorInfo GetVolumeInfo
use Win32::EventLog;
use Win32::Lanman;           # for EnumServicesStatus GetLastError LsaEnumerateAccountRights LsaEnumerateAccountsWithUserRight LsaLookupSids LsaLookupNames LsaQueryAuditEventsPolicy NetGetDCName NetShareEnum NetUserGetInfo NetUserGetLocalGroups NetUserModalsGet QueryServiceConfig WNetAddConnection
use Win32::NetAdmin qw(GroupGetMembers GetUsers GetServerDisks LocalGroupGetMembersWithDomain);
use Win32::Perms;
use Win32::Registry;
use Win32::Service qw(GetServices GetStatus);
use Win32::TieRegistry(Delimiter=>"\\");
use Win32::OLE qw(in);       # for queries
use XML::Simple;


# Version Number
my $version = 'Security Health Check v1.3.3(sep version) [2012-Jun-10]';

# Variables initialized in 2c4nt.conf
my (  $guestid,
      $serverlist,
      $domain,
      $ping_first,
      $eventlog_capacity,
      $eventlog_retension,
      $screen_saver_timeout,
      $screen_saver_active,
      @screen_saver_exes,
      $screen_saver_is_secure,
      $extended_osr_resource_check,
      $terminal_server_osr_registry_resource_check,
      $av_current_version,
      $sep_current_version,
      $sep_current_version_32,
      @av_min_version,
      $av_max_age,
      %av_final_update,
      $av_rtscan_settings,
      $sep_rtscan_settings,
      $sep_rtscan_settings_32,
      $av_history_delta_days,
      %auditpol,
      %auditpolconf,
      @auditpol,
      $restart_shutdown_system_NT,
      $restart_shutdown_system_2K,
      $logon_logoff,
      $file_object_access,
      $user_rights_use,
      $process_tracking,
      $security_policy_changes,
      $user_group_management,
      $directory_service_access,
      $min_passwd_age,
      $lockout_observation_window,
      $max_passwd_age,
      $min_passwd_len,
      $lockout_duration,
      $password_hist_len,
      $lockout_threshold,
      %everyone_perms,
      %everyone_perms_NT,
      %everyone_perms_XP,
      %everyone_perms_2K,
      %everyone_perms_2K3,
      $base_server_problems,
      $base_server_summary,
      @sysroot_resources,
      @sysdrive_resources,
      @all_resources,
      @general_users,
      @privileged_groups,
      @hotfix_registry_keys,
      @ie_hotfix_registry_keys,
      @ie_version_registry_keys,
      @ie_version_registry_key_labels,
      @hotfix_registry_keys_date_labels,
      @ms_version_registry_keys,
      @ms_service_registry_keys,
      @ms_service_account_names,
      $business_use_notice_check,
      @business_use_notice_registry_keys,
      @business_use_notice_usa,
      @business_use_notice_other,
      @registry_value_settings,
      @network_registry_value_settings,
      @registry_value_perms,
      @av_history_settings,
      @alt_av_history_settings,
      @av_history_keywords,
      @av_registry_settings,
      @sep_registry_settings,
      @sep_registry_settings_32,
      @av_versions_settings,
      @windows_update_files,
      @issi_update_files,
      @issi_history_keywords,
      @lanman_encryption_settings,
      @encrypted_filesystem_settings,
      %permissions_maps,
      @b,
      $osbit
      );

# Variables initialized in patchlist.txt
my (%hotfix);

# Variables initialized in required.txt
my (%required);

# Routine Hash which maps ITCS requirements
my %routines = (
   '00 System Information' =>
      {sub => \&sysinfo_policy,
       reference => 'System Information',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'System Information',
      },
   '01 Network Adapter Information' =>
      {sub => \&tcp_ip_policy,
       reference => 'Network Adapter Information',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Network Adapter Information',
      },
   '02 Network Share Information' =>
      {sub => \&share_policy,
       reference => 'Network Share Information',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Network Share Information',
      },
   '03 Netstat Information' =>
      {sub => \&netstat_policy,
       reference => 'Netstat Information',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Netstat Information',
      },
   '04 Service Pack and Hot Fixes' =>
      {sub => \&server_hotfix_policy,
       reference => 'ITCS104 Chapter 1.5.5 APAR - Security/Integrity PTF & Fix Implementation',
       itcs_group_one => 1,
       itcs_group_three_four => 1,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Service Pack and Hot Fixes',
      },
   '05 Audit Policy Event Settings' =>
      {sub => \&audit_policy,
       reference => '#ITCS# Section 6 Activity Auditing - Audit Policy - Event Settings',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Audit Policy Event Settings',
      },
   '06 User Account Password Settings' =>
      {sub => \&password_policy,
       reference => '#ITCS# Section 2.1 Authentication - Reusable Passwords',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'User Account Password Settings',
      },
   '07 User Account Lockout Settings' =>
      {sub => \&account_lockout_policy,
       reference => '#ITCS# Section 5.4 Systematic Logon Attacks - Account Lockout',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'User Account Lockout Settings',
      },
   '08 User Account Password Expiration' =>
      {sub => \&password_expiry_policy,
       reference => '#ITCS# Section 2.1 Authentication - Reusable Passwords - Password Expiration',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'User Account Password Expiration',
      },
   '09 Operating System Resource Settings' =>
      {sub => \&osr_policy,
       reference => '#ITCS# Section  5.1 Service Integrity & Availability - Operating System Resources',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Operating System Resource Settings',
      },
   '10 Guest Account Status' =>
      {sub => \&guest_account_policy,
       reference => '#ITCS# Section 3.2 Authorization - User Resources - Guest Account Policy',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Guest Account Status',
      },
   '11 Guest Access Restrictions' =>
      {sub => \&guest_access_policy,
       reference => '#ITCS# Section 5.1 Service Integrity & Availability - Operating System Resources - Registry Settings - Guest Access Restrictions',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,

       description => 'Guest Access Restrictions',
      },
   '12 Guest Group Membership' =>
      {sub => \&guest_group_account_policy,
       reference => '#ITCS# Section 3.2 Authorization - User Resources - Guest Account Group Membership',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Guest Group Membership',
      },
   '13 Business Use Notice' =>
      {sub => \&biz_use_notice_policy,
       reference => '#ITCS# Section 3.1 Authorization - Business Use Notice',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Business Use Notice',
      },
   '14 Security Log Retention' =>
      {sub => \&eventlog_policy,
       reference => '#ITCS# Section 6 Activity Auditing - Audit Policy - Security Log Retention',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,

       description => 'Security Log Retention',
      },
   '15 List Privileged Accounts' =>
      {sub => \&privileged_groups_policy,
       reference => '#ITCS# Section 5.2 Service Integrity & Availability - Security & System Administrative Authority',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'List Privileged Accounts',
      },
   '16 Drive Format' =>
      {sub => \&logical_drive_policy,
       reference => '#ITCS# Section 5.1 Service Integrity & Availability - Operating System Resources - Drive Format',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Drive Format',
      },
   '17 Local Logon Settings' =>
      {sub => \&local_logon_policy,
       # This check is for Section 5.1 Process exceptions
       reference => '#ITCS# Section 3.2 Authorization - User Resources - Local Logon Settings',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Local Logon Settings',
      },
   '18 AntiVirus Version and Definition Dates' =>
      {sub => \&av_policy,
       reference => '#ITCS# Section 5.3 Service Integrity & Availability - Harmful Code Detection',
       itcs_group_one => 1,
       itcs_group_three_four => 1,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'AntiVirus Version and Definition Dates',
      },
   '19 AntiVirus History Log Settings' =>
      {sub => \&av_history,
       reference => '#ITCS# Section 5.3 Service Integrity & Availability - Harmful Code Detection Logs',
       itcs_group_one => 1,
       itcs_group_three_four => 1,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'AntiVirus History Log Settings',
      },
   '20 Screensaver Settings' =>
      {sub => \&screensaver_policy,
       reference => 'Screensaver Settings',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 0,
       peer_review_itcs_group_three_four => 0,
       description => 'Screensaver Settings',
      },
   '21 Service Names and Descriptions' =>
      {sub => \&service_names_policy,
       reference => 'Service Names and Descriptions',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Service Names and Descriptions',
      },
   '22 Service Accounts Local' =>
      {sub => \&service_account_policy,
       reference => 'Service Accounts Local',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Service Accounts Local',
      },
   '23 Critical Service Status' =>
      {sub => \&critical_service_policy,
       reference => 'Critical Service Status',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Critical Service Status',
      },
   '24 Messenger Service Status' =>
      {sub => \&messenger_status_policy,
       reference => 'Messenger Service Status',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 0,
       peer_review_itcs_group_three_four => 0,
       description => 'Messenger Service Status',
      },
   '25 LanMan Password Policy Settings' =>
      {sub => \&lanman_password_policy,
       reference => '#ITCS# Section 4.1 Information Protection & Confidentiality - Encryption',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'LanMan Password Policy Settings',
      },
   '26 Store Password Using Reversible Encryption Settings' =>
      {sub => \&reversible_encryption_policy,
       reference => '#ITCS# Section 4.1 Information Protection & Confidentiality - Encryption',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 0,
       description => 'Store Password Using Reversible Encryption Settings',
      },
   '27 List All Accounts' =>
      {sub => \&list_all_accounts,
       reference => 'List All Accounts',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'List All Accounts',
      },
   '28 Network Settings' =>
      {sub => \&list_network_registry_settings,
       reference => '#ITCS# Section 8 Network Registry Settings',
       itcs_group_one => 1,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'List Network Registry Settings',
      },
   '29 System Restart Logs' =>
      {sub => \&system_restart_policy,
       reference => 'System Restart Logs',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'System Restart Logs',
      },
   '30 Installed System Applications' =>
      {sub => \&system_installed_application_policy,
       reference => 'Installed System Applications',
       itcs_group_one => 0,
       itcs_group_three_four => 0,
       peer_review_itcs_group_one => 1,
       peer_review_itcs_group_three_four => 1,
       description => 'Installed System Applications',
      }
);

# Options storage variables
my $verbose;
my $debug;
my $itcs_mode;
my $itcs_alt_mode;
my $peerReview;
my $peer_review_mode;
my $peer_review_alt_mode;
my $all_mode;
my $getglobalusers;
my $noglobalusers;
my $cdrom;
my $nopdc;
my $pdc;
my $nogui;
my $help;
my $localonly;
my $tmpmode;

my @user_servers;
my @all_routines = sort keys %routines;  # all supported routines
my @user_routines;  # default routines selected by user

my $config_file = "2c4nt.conf";
my $patch_file = "patchlist.txt";
my $required_file = "required.txt";

# Report Filename(s)
my ($serversummary, $serverproblems);
my ($logon_window_open) = 0;

# Count of errors, also tracks current server in order to insert newline when changing between servers
my %count;

# Server name for Domain Controller, blank if none
my $pdcname;

# Restart/Shutdown
my $restart_shutdown_system;

# Whether current server is PDC, BDC, standalone server, workstation
my $servertype;

# Store OS install directory
my $systemroot;

# Store OS install date
my $installdate;

# Global AV history variables
my @ndates;
my @nfiles;
my @avmsgs;
my $avmsgno=-1;
my $alt_av_history=0;

# Global UNC Path variable
my $UncPath;

####################################################################
# Main Program
#
#
#
#
#
#
#
####################################################################

if ($PerlApp::VERSION) {
   print "Program is compiled with PerlApp ($PerlApp::VERSION)...\n";
} elsif ($^X =~ /(perl)|(perl\.exe)$/i) {
   print "Using perl interpreter...\n";
} else {
   print "Program is compiled with perl2exe...\n";
}

# get the command line options, these will be the defaults for the GUI
if (!GetOptions( 'sub=s'           => \@user_routines,
                 'server=s'        => \@user_servers,
                 'pdc=s'           => \$pdc,
                 'getglobalusers'  => \$getglobalusers,
                 'noglobalusers'   => \$noglobalusers,
                 'nopdc'           => \$nopdc,
                 'itcs104'         => \$itcs_mode,
                 'itcs104alt'      => \$itcs_alt_mode,
                 'peer-review'     => \$peer_review_mode,
                 'peer-review-alt' => \$peer_review_alt_mode,
                 'altavhistory'    => \$alt_av_history,
                 'cdrom'           => \$cdrom,
                 'nogui'           => \$nogui,
                 'localonly'       => \$localonly,
                 'verbose!'        => \$verbose,
                 'debug'           => \$debug,
                 'help|h|?'        => \$help)
   ) {
   # command line was invalid, so exit and GetOptions will print its own error msgs
   exit(1);
}

# quick and dirty help
if ($help) {
   print "$version\n";
   my $help = <<HELP;
   Command line options
      -sub <routine>    add a user defined routine
      -server <name>    add a server to test
      -pdc <name>       specify a PDC
      -getglobalusers   process user account tests
      -noglobalusers    skip user account tests
      -nopdc            standalone machine
      -itcs104          enable all ITCS104 (Group 1) tests
      -itcs104alt       enable all ITCS104 (Group 3/4) tests
      -peer-review      enable all Peer Review (Group 1) tests
      -peer-review-alt  enable all Peer Review (Group 3/4) tests
      -altavhistory     search alternate AV history locations (for faster searches)
      -cdrom            running from a CD-ROM
      -nogui            supress GUI
      -localonly        run test(s) in non-networked mode
      -verbose          report current settings when reporting failures
      -noverbose        do not report current settings when reporting failures
      -debug            print additional debugging information

HELP

   print $help;
   exit(1);
}

####################################################################
# Read in the configuration files
#
#
#
#
#
#
#
####################################################################


read_config_file($config_file);

if (!defined($base_server_summary)) {
   print "Invalid configuration data in $config_file\n";
   exit 1;
}

read_config_file($patch_file);
read_config_file($required_file);

if (scalar(@user_servers) == 0) {
   # get the list of servers from the server list input file
   read_server_list("serverlist.txt");
}

if (!$nogui ) {
   # pop up the GUI
   @user_routines = sort keys %routines; # default routines selected by user
   tk_main_window();
} else {
   if ($itcs_mode == 1) {
      @user_routines = ();
      foreach (%routines) {
         if ( $routines{$_}->{'itcs_group_one'} ) {
            push(@user_routines, $_);
         }
      }
   } else {
      if ($itcs_alt_mode == 1) {
         @user_routines = ();
         foreach (%routines) {
            if ( $routines{$_}->{'itcs_group_three_four'} ) {
               push(@user_routines, $_);
            }
         }
      } else {
         if ($peer_review_mode == 1) {
            @user_routines = ();
            foreach (%routines) {
               if ( $routines{$_}->{'peer_review_itcs_group_one'} ) {
                  push(@user_routines, $_);
               }
            }
         } else {
            if ($peer_review_alt_mode == 1) {
               @user_routines = ();
               foreach (%routines) {
                  if ( $routines{$_}->{'peer_review_itcs_group_three_four'} ) {
                     push(@user_routines, $_);
                  }
               }
            } else {
               if ( !@user_routines ) {
                  @user_routines = sort keys %routines; # default routines selected by user
               }
            }
         }
      }
   }

   @user_routines = sort @user_routines;

   # run the report directly
   my $return_code = run_report();

   if ($return_code == 1) {
      print "No security tests were selected.  Nothing to do!\n";
      exit(2);
   } elsif ($return_code == 2) {
      print "No servers were selected.  Nothing to do!\n";
      exit(3);
   }
}

exit(0);

#=---------------------- begin main loop -------------------------=#

####################################################################
# run report
#
#
#
#
#
#
#
####################################################################

sub run_report () {
   my ($server);
   my ($fqdn);
   my ($response);
   my ($sec, $min, $hour, $day, $month, $year);
   my ($dateformat);

   # If no specific routines or systems selected then exit
   if (scalar(@user_routines) == 0) {
      return (1);
   }
   if (scalar(@user_servers) == 0) {
      return (2);
   }

   foreach $server (@user_servers) {
      # Calculate the date
      ($sec, $min, $hour, $day, $month, $year) = get_date();

      # Determine report filename format

      # If the servername is localhost or 127.0.0.x set the name to local Windows name
      if ($server eq "localhost" || $server =~ /^127\.[0-9]+\.[0-9]+\.[0-9]+$/) {
         $server = hostname();
         $fqdn = hostfqdn();
         $serversummary = "$fqdn";
         $serverproblems = "$fqdn";
      } else {
         # If there is only one server, use it in the output file name
         if (scalar(@user_servers) == 1 ) {
            $server = $user_servers[0];
            if ( $serversummary !~ m/$server/ ) {
               $serversummary = "$server";
               $serverproblems = "$server";
            }
         } else {
            $serversummary = "multiple";
            $serverproblems = "multiple";
         }
      }

      # Proposed output file format: FQDN-OS-yyyymmdd.txt
      # <hostname>.<site>.ibm.com-<CHECK | SSH | Samba | APAR | CCHC | NTCHECK>-<$DATE>.txt

      #$dateformat = sprintf("%04d%02d%02d-%02d%02d", $year, $month, $day, $hour, $min);
      $dateformat = sprintf("%04d%02d%02d", $year, $month, $day);

      # Best format for sorting files
      $serversummary = "$serversummary-NTCHECK-$dateformat-$base_server_summary";
      $serverproblems = "$serverproblems-NTCHECK-$dateformat-$base_server_problems";

      # This next option is handy if you are running a report for several standalone systems and want to use the same floppy
      # If running from CDROM we only test the current system and we save to the floppy drive

      if ($cdrom) {
         my ($localname) = hostname();
         @user_servers = ($localname);
         if ( $serversummary !~ m/$localname/ ) {
            $serversummary = "a:\\$localname.$serversummary";
            $serverproblems = "a:\\$localname.$serverproblems";
         }
      }

      # FIXME: add prefix selection to GUI

      # Open output file for reports
      open(SUMMARY,">$serversummary") || die($!." : $serversummary");
      open(PROBLEMS,">$serverproblems") || die($!." : $serverproblems");

      next if $server !~ /^\S+/;
      chomp $server;

      # Retrieve osversion, servicepack, architecture, os descrition, systemroot, partition and install date
      my ($osversion, $osservicepack, $osarch, $osstring, $ossystemroot, $ospartition, $osinstalldate) = get_os_version($server);

      # Set the global variable(s) for systemroot and installdate here, they should have been retrieved via get_os_version
      $systemroot = $ossystemroot;
      $installdate = $osinstalldate;

      # Test to see if server is available on the network
      if ( $ping_first eq "yes" && $server ne (hostname()) ) {
         # find out what type of ping we can support
         $response = ping_host($server, $osversion, $osservicepack, $osarch);
      } else {
         $response = "TRUE";
      }

      reporttext("Date: " . sprintf("%02d/%02d/%04d", $month, $day, $year) . "\n");
      reporttext("Time: " . sprintf("%02d:%02d:%02d", $hour, $min, $sec) . "\n");
      reporttext("Server: $server\n");
      reporttext("Version: $version\n");

      # Print the Reporting Type
      if ($itcs_mode == 1) {
         $tmpmode = 1;
      }

      if ($itcs_alt_mode == 1) {
         $tmpmode = 2;
      }

      if ($peer_review_mode == 1) {
         $tmpmode = 3;
      }

      if ($peer_review_alt_mode == 1) {
         $tmpmode = 4;
      }

      if ($all_mode == 1) {
         $tmpmode = 5;
      }

      reporttext("Report Type: ");

      if ($tmpmode == 1) {
         reporttext("ITCS104 Group One");
      } elsif ($tmpmode == 2) {
         reporttext("ITCS104 Group Three and Four");
      } elsif ($tmpmode == 3) {
         reporttext("Peer Review ITCS104 Group One");
      } elsif ($tmpmode == 4) {
         reporttext("Peer Review ITCS104 Group Three and Four");
      } elsif ($tmpmode == 5) {
         reporttext("All Routines");
      } else {
         reporttext("Manually Selected Routine(s)");
      }

      reporttext("\n");
      reporttext("\n");

      reporttext("*** IBM Confidential ***\n");

      if ($response ne "TRUE") {
         reporterror($server, "Server did not respond to ICMP ping request, skipping host");
         &tk_show_error("$server: Server did not respond to ICMP \n ping request, skipping host.", 350, 75, 100, 250);
         close SUMMARY;
         close PROBLEMS;
         next;
      }

      if ($localonly) {
         if ($server ne hostname()){
            reporterror($server, "Server mismatch, cannot run query against other host(s) when -localonly option is selected");
            &tk_show_error("$server: Server mismatch, cannot run query against \n other host(s) when -localonly option is selected.", 350, 75, 100, 250);
            close SUMMARY;
            close PROBLEMS;
            next;
         }
      }

      # Depending on OS map the shutdown setting requirement and the permissions maps from the config file

      if ($osversion eq "3.5" || $osversion eq "3.51" || $osversion eq "4.0") {
         $restart_shutdown_system = $restart_shutdown_system_NT;
         %everyone_perms = %{ clone (\%everyone_perms_NT) };
      } elsif ($osversion eq "5.0") {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_2K) };
      } elsif ($osversion eq "5.1") {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_XP) };
      } elsif ($osversion eq "5.2") {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_2K3) };
      } elsif ($osversion eq "5.3") {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_2K3) };
      } elsif ($osversion eq "6.0") {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_2K3) };
      } else {
         $restart_shutdown_system = $restart_shutdown_system_2K;
         %everyone_perms = %{ clone (\%everyone_perms_2K3) };
      }

      # Find the Domain Controller
      if (!$nopdc) {
         if ($domain) {
            if ($pdc) {
               $pdcname = $pdc;
            } else {
               $pdcname = find_pdc($server, $domain) if !$localonly;
            }
         } else {
            # Get current DOMAIN if not set and find the PDC
            $domain = Win32::DomainName() if !$localonly;
            $pdcname = find_pdc($server, $domain) if !$localonly;
         }
      }

      # Not sure if we should attempt to define the PDC as the localsystem if localonly option selected
      #if ($localonly) { $pdcname = $server; }

      # Print out Domain Controller Info
      if ($verbose) {
         if ($pdcname) {
            reporttext("\tPrimary Domain Controller is $pdcname in [$domain]\n");
         }
      }

      # Get the server type
      $servertype = get_server_type($server, $osstring);

      # If ITCS104 enabled, also run getglobalusers unless noglobalusers flag is set
      if ($itcs_mode == 1 || $itcs_alt_mode == 1) {
         $getglobalusers = 1 unless $noglobalusers;
      }

      foreach my $routine (@user_routines) {
         my ($routine_error);
         strip_list($routine);
         next if $routine !~ /^\S+/;
         chomp $routine;
         # print the title for this check
         reporttext(format_title($routine, $server, $osversion));
         # call the routine for this check
         &{$routines{$routine}->{sub}}($server, $osversion, $osservicepack, $osarch);
      }

      $count{'failures'} = "no" unless $count{'failures'};

      reporttext("\n");

      if ($count{'failures'} == 1) {
         reporttext("Looks like there was $count{'failures'} violation\n");
      } else {
         reporttext("Looks like there were $count{'failures'} violations\n");
      }
      reporttext("\n");

      # Reset counter in case Run Report is pressed again
      $count{'failures'} = 0;

      close SUMMARY;
      close PROBLEMS;

      &tk_view_results($serversummary);
   }

   return (0);
}

#=-------------------- begin GUI routines ------------------------=#

####################################################################
# Show error dialogue box
#
#
#
#
#
#
#
####################################################################

sub tk_show_error ($$$$$) {
   my ($error, $width, $height, $positionX, $positionY) = @_;

   my ($f);
   my $mw = MainWindow->new;
   $mw->geometry("$width"."x"."$height"."+"."$positionX"."+"."$positionY");

   # Create necessary widgets
   $f = $mw->Frame->pack(-side => 'top', -fill => 'x');
   $f->Label(-text => "\nERROR: $error\n")->pack(-side => 'top', -anchor => 'c');
   #$f->Label(-text => "ERROR: $error")->place(-relx => 0.5, -rely => 0.5);
   $f->Button(-text => 'Close', -command => sub { $mw->destroy() if Tk::Exists($mw); } )->pack(-side => 'bottom');
}

####################################################################
# show the report in a separate window
#
#
#
#
#
#
#
####################################################################

sub tk_logon_window () {
   my ($domain, $server, $user, $password);
   my ($f1, $f2, $f3, $f4, $f5, $f6);

   if ($logon_window_open) {
      return();
   }
   $logon_window_open = 1;

   $domain = "";
   $server = "";
   $user = "Administrator";
   $password = "";

   # Create necessary widgets
   my $mw = MainWindow->new(-title => 'Logon');

   $f1 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f1->Label(-text => 'Authenticate User')->pack(-side => 'top', -pady => 4, -padx => 4);

   $f2 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f2->Label(-text => 'User:')->pack(-side => 'left');
   $f2->Entry(-textvariable => \$user)->pack(-side => 'right', -pady => 2, -padx => 2, -fill => 'x', -expand => 1);

   $f3 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f3->Label(-text => 'Password:')->pack(-side => 'left');
   $f3->Entry(-textvariable => \$password, -show => 0)->pack(-side => 'right', -pady => 2, -padx => 2, -fill => 'x', -expand => 1);

   $f4 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f4->Label(-text => 'Domain:')->pack(-side => 'left');
   $f4->Entry(-textvariable => \$domain)->pack(-side => 'right', -pady => 2, -padx => 2, -fill => 'x', -expand => 1);

   $f5 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f5->Label(-text => 'Server:')->pack(-side => 'left');
   $f5->Entry(-textvariable => \$server)->pack(-side => 'right', -pady => 2, -padx => 2, -fill => 'x', -expand => 1);

   $f6 = $mw->Frame->pack(-side => 'top', -fill => 'x', -expand => 1);
   $f6->Button(-text => 'Logon', -command => sub { logon_as_user($domain, $server, $user, $password); $mw->destroy() if Tk::Exists($mw); $logon_window_open = 0; } )->pack(-side => 'left', -pady => 4, -padx => 20, -fill => 'x');
   $f6->Button(-text => 'Cancel', -command => sub { $mw->destroy() if Tk::Exists($mw); $logon_window_open = 0; } )->pack(-side => 'right', -pady => 4, -padx => 20, -fill => 'x');
}

####################################################################
# show the report in a separate window
#
#
#
#
#
#
#
####################################################################

sub tk_view_results ($) {
   my ($filename) = @_;
   my ($f, $t);

   my $mw = MainWindow->new(-title => 'Server Summary Report');

   # Create necessary widgets
   $f = $mw->Frame->pack(-side => 'top', -fill => 'x');

   $f->Label(-text => 'Filename:')->pack(-side => 'left');
   $f->Label(-text => "$filename")->pack(-side => 'left', -fill => 'x', -expand => 1);
   $f->Button(-text => ' Close ', -command => sub { $mw->destroy() if Tk::Exists($mw); } )->pack(-side => 'right');
   $mw->Label(-text => ' ', -relief => 'ridge')->pack(-side => 'top', -fill => 'x');

   $t = $mw->Scrolled('ROText', -wrap => 'none', -scrollbars => 'osre')->pack(-side => 'bottom', -fill => 'both', -expand => 1);

   if (open(FH, "$filename")) {
     while (<FH>) {
        $t->insert('end', $_);
     }
     close(FH);
   } else {
      tk_show_error("Unable to read summary report from file.", 350, 75, 100, 250);
   }
}

####################################################################
# build the main window
#
#
#
#
#
#
#
####################################################################

# Tk window variables
#   my $mw;
#   my ($frame1, $frame2, $frame2a, $frame2b, $frame3, $frame3a, $frame3b, $frame4, $frame5, $frame5a, $frame5b, $frame6);
#   my $buttonITCS104GroupOne;
#   my $buttonITCS104GroupThreeFour;
#   my $buttonDomainUsers;
#   my $buttonVerbose;
#   my $buttonCDROM;
#   my $buttonStandAlone;
#   my $buttonAll;
#   my $buttonSelected;
#   my $buttonPeerReview;
#   my $buttonBlank;
#   my $blank;
#   my $routineRadioValue=0;

# Tk window list box variables
#   my $listboxHostList;
#   my $listboxHostListSelected;

#   my $listboxRoutineList;
#   my @listboxRoutineListSelected;

#   # Tk window text box variables
#   my $textboxPDC;
#   my $textboxPDCList;
#   my $textboxTarget;
#   my $textboxHostList;

#   my $groupType;
#   my $groupPType;

sub tk_main_window () {

   # Tk window variables
   my $mw;
   my ($frame1, $frame2, $frame2a, $frame2b, $frame3, $frame3a, $frame3b, $frame4, $frame5, $frame5a, $frame5b, $frame6);
   my $buttonITCS104GroupOne;
   my $buttonITCS104GroupThreeFour;
   my $buttonDomainUsers;
   my $buttonVerbose;
   my $buttonCDROM;
   my $buttonStandAlone;
   my $buttonAll;
   my $buttonSelected;
   my $buttonPeerReview;
   my $buttonBlank;
   my $blank;
   my $routineRadioValue=0;

   # Tk window list box variables
   my $listboxHostList;
   my $listboxHostListSelected;

   my $listboxRoutineList;
   my @listboxRoutineListSelected;

   # Tk window text box variables
   my $textboxPDC;
   my $textboxPDCList;
   my $textboxTarget;
   my $textboxHostList;

   # Group types for distinguisning between ITCS or Peer Review mode
   my $groupType;
   my $groupPType;

   my $item;

   $mw = MainWindow->new(-title => "$version");
   $mw->geometry("600x480+10+10");

   $frame1 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both');
   $frame1->Label(-text => "Microsoft Windows XP/VISTA/7/2003/2008 Health Check Utility - SEP version")->pack;

   $frame2 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both', -expand => 1);
   $frame2->Label(-text => "Select Server(s) to Check:")->pack;

   $frame2a = $frame2->Frame(-borderwidth => 1)->pack(-side => 'left', -fill => 'both', -expand => 1);
   $frame2a->Label(-text => "Select From serverlist.txt:")->pack;

   $listboxHostList = $frame2a->Scrolled('Listbox', -scrollbars => 'osoe', -height => 4, -width => 30, -selectmode => 'extended', -exportselection => 0)->pack(-side => 'left', -fill => 'both', -expand => 1);
   $listboxHostList->insert('end', sort @user_servers);

# FIXME: Should middle of next line have "if" or "unless"... it sets focus unconditionally right now
#  $listboxHostList->bind("<ButtonPress>", [ sub { $textboxHostList->delete("0.0", 'end'); $textboxHostList eq ""; $listboxHostList->focus(); }, Ev("X"), Ev("Y") ] );

   $listboxHostList->bind("<ButtonPress>", [ sub { $textboxHostList->delete("0.0", 'end'); $listboxHostList->focus(); }, Ev("X"), Ev("Y") ] );

   $frame2b = $frame2->Frame(-borderwidth => 1)->pack(-side => 'right', -fill => 'both', -expand => 1);
   $frame2b->Label(-text => "- Or -")->pack(-side => 'top', -fill => 'both');
   $frame2b->Label(-text => "Specify Server Name:")->pack(-side => 'top', -anchor => 'sw', -fill => 'x', -expand => 1);

   $textboxHostList = $frame2b->Entry(-textvariable => \$textboxTarget)->pack(-padx => '5', -side => 'top', -anchor => 'nw', -fill => 'x', -expand => 1);
   $textboxHostList->bind("<KeyPress>", [ sub { $listboxHostList->selectionClear(0, 'end'); }, Ev("K") ] );

   $frame3 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both', -expand => 1);
   $frame3->Label(-text => "Choose Security Checks:")->pack;

   $frame3a = $frame3->Frame(-borderwidth => 1)->pack(-side => 'left', -fill => 'both', -expand => 1);

   $listboxRoutineList = $frame3a->Scrolled('Listbox', -scrollbars => 'osoe', -height => 4, -width => 30, -selectmode => 'extended', -exportselection => 0)->pack(-side => 'left', -fill => 'both', -expand => 1);
   $listboxRoutineList->insert('end', @user_routines);
   $listboxRoutineList->bind("<ButtonPress>", [ sub { $buttonPeerReview->deselect(); $routineRadioValue = 0; $listboxRoutineList->focus(); }, Ev("X"), Ev("Y") ] );

   # reset groupType
   $groupType = '';
   # reset groupPType
   $groupPType= '';
   # reset all_mode
   $all_mode = 0;
   # reset routineRadioValue
   $routineRadioValue = 0;
   # reset item count
   $item = 0;

   # if $itcs_mode is on from command line, preselect routines
   if ($itcs_mode) {
      $groupType='itcs_group_one';
      $listboxRoutineList->selectionSet(0, 'end');
      map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'itcs_group_one'}); $item++;} @all_routines;
      $routineRadioValue = 1;
   }

   # if $itcs_mode is on from command line, preselect routines
   if ($itcs_alt_mode) {
      $groupType='itcs_group_three_four';
      $listboxRoutineList->selectionSet(0, 'end');
      map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'itcs_group_three_four'}); $item++;} @all_routines;
      $routineRadioValue = 2;
   }

   # if $itcs_mode is on from command line, preselect routines
   if ($peer_review_mode) {
      $groupType='peer_review_itcs_group_one';
      $listboxRoutineList->selectionSet(0, 'end');
      map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'peer_review_itcs_group_one'}); $item++;} @all_routines;
      #$routineRadioValue = 0;
   }

   # if $itcs_mode is on from command line, preselect routines
   if ($peer_review_alt_mode) {
      $groupType='peer_review_itcs_group_three_four';
      $listboxRoutineList->selectionSet(0, 'end');
      map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'peer_review_itcs_group_three_four'}); $item++;} @all_routines;
      #$routineRadioValue = 0;
   }

   $frame3b = $frame3->Frame(-borderwidth => 1)->pack(-side => 'right', -fill => 'both');
   $buttonSelected = $frame3b->Radiobutton(-text => "Selected Checks", -variable => \$routineRadioValue, -value => 0)->pack(-side => 'top', -anchor => 'nw', -fill => 'y', -expand => 1);

   $buttonITCS104GroupOne = $frame3b->Radiobutton(-text => "ITCS104 Group 1 Compliance Checks", -variable => \$routineRadioValue, -value => 1)->pack(-side => 'top', -anchor => 'w', -fill => 'y', -expand => 1);
   $buttonITCS104GroupOne->bind("<ButtonPress>", [ sub { $buttonDomainUsers->select(); $buttonPeerReview->deselect(); $all_mode = 0; $itcs_alt_mode = 0; $item = 0; $groupPType='peer_review_itcs_group_one'; $listboxRoutineList->selectionSet(0, 'end'); map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'itcs_group_one'}); $item++;} @all_routines; }, Ev("X"), Ev("Y") ] );

   $buttonITCS104GroupThreeFour = $frame3b->Radiobutton(-text => "ITCS104 Group 3/4 Compliance Checks", -variable => \$routineRadioValue, -value => 2)->pack(-side => 'top', -anchor => 'w', -fill => 'y', -expand => 1);
   $buttonITCS104GroupThreeFour->bind("<ButtonPress>", [ sub { $buttonDomainUsers->deselect(); $buttonPeerReview->deselect(); $all_mode = 0; $itcs_mode = 0; $item = 0; $groupPType='peer_review_itcs_group_three_four'; $listboxRoutineList->selectionSet(0, 'end'); map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{'itcs_group_three_four'}); $item++;} @all_routines; }, Ev("X"), Ev("Y") ] );

   $buttonAll = $frame3b->Radiobutton(-text => "All Checks", -variable => \$routineRadioValue, -value => 3)->pack(-side => 'top', -anchor => 'sw', -fill => 'y', -expand => 1);
   $buttonAll->bind("<ButtonPress>", [ sub { $buttonDomainUsers->select(); $buttonPeerReview->deselect(); $all_mode = 1; $itcs_mode = 0; $itcs_alt_mode = 0; $item = 0; $listboxRoutineList->selectionSet(0, 'end'); }, Ev("X"), Ev("Y") ] );

   $frame4 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both');
   $frame4->Label(-text => "Report Options:")->pack;

# FIXME: Hide for now
#   $frame4->Button(-text => "Logon", -command => sub { &tk_logon_window(); })->pack(-side => 'left', -pady => 2, -padx => 2);

   $buttonPeerReview = $frame4->Checkbutton(-text => "Enable additional Peer Review reporting", -variable => \$peerReview)->pack(-side => 'left', -expand => 1);
   $buttonPeerReview->bind("<ButtonPress>", [ sub {
      if ($groupPType eq 'peer_review_itcs_group_three_four') {
         $item = 0;
         $groupType='peer_review_itcs_group_three_four';
         $listboxRoutineList->selectionSet(0, 'end');
         $itcs_mode = 0;
         $itcs_alt_mode = 0;
         $peer_review_alt_mode = 1;
         $peer_review_mode = 0;
         map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{$groupType}); $item++;} @all_routines;
      } else {
         if ($groupPType eq 'peer_review_itcs_group_one') {
            $item = 0;
            $groupType='peer_review_itcs_group_one';
            $listboxRoutineList->selectionSet(0, 'end');
            $itcs_mode = 0;
            $itcs_alt_mode = 0;
            $peer_review_alt_mode = 1;
            $peer_review_mode = 0;
            map { $listboxRoutineList->selectionClear($item) if (! $routines{$_}->{$groupType}); $item++;} @all_routines;
         }
      }

   } ]);

   $buttonVerbose = $frame4->Checkbutton(-text => "Verbose reporting of current settings", -variable => \$verbose)->pack(-side => 'right', -expand => 1);

   $frame5 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both');
   $frame5->Label(-text => "Additional Settings:")->pack;

   $frame5a = $frame5->Frame(-borderwidth => 1)->pack(-side => 'left', -fill => 'both');
   $buttonStandAlone = $frame5a->Checkbutton(-text => "Standalone Server [no Domain configured]", -variable => \$nopdc)->pack(-side => 'top', -anchor => 'nw', -expand => 1);
   $buttonStandAlone->bind("<ButtonPress>", [ sub { $textboxPDCList->delete("0.0", 'end'); }, Ev("X"), Ev("Y") ] );

   $buttonCDROM = $frame5->Checkbutton(-text => "Running from CDROM --> Output to floppy", -variable => \$cdrom)->pack(-side => 'top', -expand => 1);

   $buttonDomainUsers = $frame5a->Checkbutton(-text => "Check accounts for \"Password Never Expires\"", -variable => \$getglobalusers, -wraplength => 300)->pack(-side => 'bottom', -anchor => 'sw', -expand => 1);
   #$buttonDomainUsers->bind("<ButtonPress>", [ sub { $buttonStandAlone->deselect(); }, Ev("X"), Ev("Y") ] );

   my $buttonLocalOnly = $frame5a->Checkbutton(-text => "Perform local only check(s) [minimal networking]", -variable => \$localonly, -wraplength => 300)->pack(-side => 'bottom', -anchor => 'sw', -expand => 1);

   my $buttonAltAVHistory = $frame5a->Checkbutton(-text => "Search only default AV history location(s) [faster searching]", -variable => \$alt_av_history, -wraplength => 300)->pack(-side => 'bottom', -anchor => 'sw', -expand => 1);

   $frame5b = $frame5->Frame(-borderwidth => 1)->pack(-side => 'right', -fill => 'both');
   $frame5b->Label(-text => "If you have multiple domains, enter PDC of Domain to focus:")->pack(-side => 'top');
   #$frame5b->Label(-text => "Specify PDC:")->pack(-side => 'top');
   $textboxPDCList = $frame5b->Entry(-textvariable => \$pdc)->pack(-side => 'top', -padx => 10, -pady => 2, -fill => 'both', -expand => 0);
   $textboxPDCList->bind("<KeyPress>",  [ sub { $buttonStandAlone->deselect(); }, Ev("K") ] );

   # if $itcs_mode is on from command line, also select domain users check
   if ($itcs_mode || $peer_review_mode) {
      $buttonDomainUsers->toggle() unless $noglobalusers;
   }

   $frame6 = $mw->Frame(-borderwidth => 3, -relief => 'groove')->pack(-side => 'top', -fill => 'both');
   $frame6->Button(-text => "Run Report", -command =>

      sub {

         # load server list from server listbox, if nothing in the textbox
         @user_servers = ();
         if ($textboxTarget) {
            @user_servers = $textboxTarget;
         } else {
            foreach my $selection ($listboxHostList->curselection()) {
               push(@user_servers,$listboxHostList->get($selection));
            }
         }

         # load routines from routine listbox
         @user_routines = ();
         foreach my $selection ($listboxRoutineList->curselection()) {
            push(@user_routines,$listboxRoutineList->get($selection));
         }

         reportdebug("user_routines: @user_routines");

         # generate the report
         my $return_code = run_report();

         # view the results
         if ($return_code == 0) {
            #&tk_view_results($serversummary);
         } elsif ($return_code == 1) {
            &tk_show_error("No security tests were selected.  Nothing to do.", 350, 75, 100, 250);
         } elsif ($return_code == 2) {
            &tk_show_error("No servers were selected.  Nothing to do.", 350, 75, 100, 250);
         } else {
            &tk_show_error("Report could not be generated because of error $return_code.", 350, 75, 100, 250);
         }
      }

   )->pack(-side => 'left', -pady => 2, -padx => 40, -fill => 'x', -anchor => 'center');

   $frame6->Button(-text => " Exit ", -command => sub { exit(0); })->pack(-side => 'right', -pady => 2, -padx => 40, -fill => 'x');

   MainLoop();
}


#=------------------ begin helper routines -----------------------=#

####################################################################
# strip unwanted characters from a list
#
#
#
#
#
#
#
####################################################################

sub strip_list (@) {
   my (@array) = @_;
   my (@clean);
   my $newitem;

   @clean = ();
   foreach my $item ( @array ) {
      $newitem = $item;

      chomp $newitem;

      $newitem =~ s/#.*//;  # delete comments
      $newitem =~ s/\[.*//; # delete brackets
      $newitem =~ s/^\s+//; # delete starting whitespace
      $newitem =~ s/\s.*//; # delete other whitespace and everything after it

      if ($newitem ne "") {
         push @clean, $newitem;
      }
   }

   return(sort {$a cmp $b } @clean);
}

####################################################################
# strip unwanted characters from passed value
#
#
#
#
#
#
#
####################################################################

sub strip_item (@) {
   my (@array) = @_;
   my (@clean);
   my $newitem;

   @clean = ();
   foreach my $item ( @array ) {
      chomp $item;
      $item =~ s/#.*//;  # delete comments
      $item =~ s/\[.*//; # delete brackets
      $item =~ s/^\s+//; # delete starting whitespace
      $item =~ s/\s.*//; # delete other whitespace and everything after it
      #$item =~ s/\S+//;
      push @clean, $newitem;
   }

   return(@clean);
}

####################################################################
# get list of servers from serverlist.txt
#
#
#
#
#
#
#
####################################################################

sub read_server_list ($) {
   my ($filename) = @_;

   open(SERVER, $filename) || die ("Failed to read server list file $filename: $!\n");

   @user_servers = <SERVER>;
   close SERVER;

   @user_servers = &strip_list(@user_servers);

   return();
}

####################################################################
# read in configuration file and eval contents
#
#
#
#
#
#
#
####################################################################

sub read_config_file ($) {
   my ($filename) = @_;
   my ($line, $contents);
   my (@config);

   # open file
   if ( open(CFG,"<$filename") ) {
      # slurp the file in
      while ($line = <CFG>) {
         $contents .= $line;
      }
      # close config file
      close(CFG);
      # eval the file
      eval($contents);
      return();
   } else {
      # close config file
      close(CFG);
      print ("Failed to read configuration $filename: $!\n");
      return();
   }
   return();
}

####################################################################
# read in generic file, dump information into array
#
#
#
#
#
#
#
####################################################################

sub read_file ($) {
   my ($filename) = @_;

   my ($line, $contents);
   my (@log) = 0;

   # open file
   if ( open(CFG,"<$filename") ) {
      # slurp the file in
      while ($line = <CFG>) {
         chomp $line;
         push(@log,$line);
      }
   } else {
      print ("Failed to read file $filename: $!\n");
      close(CFG);
      return(@log);
   }

   # close config file
   close(CFG);

   return(@log);
}

####################################################################
# Used by other reporting subroutines to write to stdout, summary
# log, and problem log.
#
#
#
#
#
#
#
####################################################################

sub logproblem ($$$) {
   my ($server, $errortype, $errormsg) = @_;

   # Make sure there're no carriage returns or spaces at the end of the errormsg
   $errormsg =~ s/\s+$//s;
   $count{'lastservlogged'} = $server;

   if ($nogui) {
      print STDOUT "\t$errortype $errormsg\n";
   }
   print SUMMARY "\t$errortype $errormsg\n";
   print PROBLEMS "$server: $errortype $errormsg\n";

   return();
}

####################################################################
# Used to report missing files, registry keys, or other problems
# which prevented checks from being performed.
#
#
#
#
#
#
#
####################################################################

sub reporterror ($$) {
   my ($server, $errormsg) = @_;

   logproblem($server, 'ERROR!', $errormsg);
   return();
}

####################################################################
# Used to report syscall failures, missing files, registry keys, or
# other problems which prevented checks from being performed.
# Use only when a Win32 call fails.  Use reporterror() for any other
# error reporting.
#
#
#
#
#
#
#
####################################################################

sub reportsyserror ($$$) {
   my ($server, $errorid, $errormsg) = @_;

   # FIXME: GetLastError doesn't always return
   # my $errorid = Win32::GetLastError();
   my $errortxt = Win32::FormatMessage($errorid);

   reporterror($server, "$errormsg: $errortxt");
   return();
}

####################################################################
# Used to report compliance findings.
#
#
#
#
#
#
#
####################################################################

sub reportfail ($$) {
   my ($server, $errormsg) = @_;

   logproblem($server, 'FAIL!', $errormsg);
   $count{'failures'}++;
   return();
}

####################################################################
# Used to report security findings not related to standards
# compliance.
#
#
#
#
#
#
####################################################################

sub reportwarn ($$) {
   my ($server, $errormsg) = @_;

   logproblem($server, 'WARN!', $errormsg);
   return();
}

####################################################################
# Used to report everything else.  Logs to STDOUT and SUMMARY.
#
#
#
#
#
#
#
####################################################################

sub reporttext (@) {
   my ($errormsg) = @_;

   if ($nogui) {
      print STDOUT "$errormsg";
   }
   print SUMMARY "$errormsg";
   return();
}

####################################################################
# Used to report debugging messages
#
#
#
#
#
#
#
####################################################################

sub reportdebug (@) {
   my ($errormsg) = @_;

   if ($debug) {
      reporttext("\tDEBUG: $errormsg\n");
   }
   return();
}

####################################################################
# return correct ITCS technical section name
#
#
#
#
#
#
#
####################################################################

sub itcs_appendix ($$) {
   my ($server, $osversion) = @_;

   if ($osversion =~ 3.5 || $osversion =~ 4.0) {
      return 'ITCS104 Chapter 2.1.4';
   }
   if ($osversion =~ 5.0 || $osversion =~ 5.1) {
      return 'ITCS104 Chapter 2.1.3';
   }
   if ($osversion =~ 5.2) {
      return 'ITCS104 Chapter 2.1.11';
   }
   return "ITCS104 (Windows version $osversion)";
}

####################################################################
# format subroutine title based on os version
#
#
#
#
#
#
#
####################################################################

sub format_title ($$$) {

   my ($routine, $server, $osversion) = @_;
   my ($Title, $ITCS);

   $ITCS = itcs_appendix($server, $osversion);

   chomp($routine);

   reportdebug("routine: $routine");

   die "unrecognized routine $routine\n" if not $routines{$routine}{reference};

   $Title = $routines{$routine}{reference};
   $Title =~ s/#ITCS#/$ITCS/;
   return "\n\t--- $Title ---\n\n";
}

####################################################################
#
# Description: perform network ping test to see if server is active
#
# Accepts: server
#
# Returns: TRUE
#          FALSE
#
####################################################################

sub ping_host ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($ping);

   if ($osversion < 3.5) {
      reporterror($server, "unable to resolve system ping type!");
      return("FALSE");
   }

   if ( $osversion < 5 ) {
      $ping = Net::Ping->new("icmp");
   } else {
      $ping = Net::Ping->new();
   }

   my $alive = $ping->ping($server, 2);
   $ping->close();

   if (!defined($alive)) {
      reporterror($server, "unable to resolve hostname before ping!");
      return("FALSE");
   }
   if ($alive) {
      return("TRUE");
   } else {
      return("FALSE");
   }
}

####################################################################
#
# Description: compute the date and time
#
# Accepts: nothing
#
# Returns: SEC, MIN, HOUR, DAY, MONTH, YEAR
#
####################################################################

sub get_date () {
   my ($SEC, $MIN, $HOUR, $DAY, $MONTH, $YEAR);
   ($SEC, $MIN, $HOUR, $DAY, $MONTH, $YEAR) = (localtime)[0..5];
   $MONTH++;
   $YEAR = $YEAR+1900;
   return($SEC, $MIN, $HOUR, $DAY, $MONTH, $YEAR);
}

####################################################################
#
# Description: find the PDC if defined
#
# Accepts: server
#          domain
#
# Returns: PDC name
#
####################################################################

sub find_pdc ($$) {
   my ($server, $domain) = @_;
   my ($temppdc) = "Unknown";

   if ($localonly) {
      reportwarn($server, "running with localonly option enabled, cannot retrieve domain controller info");
      return($temppdc);
   } else {
      if (!Win32::Lanman::NetGetDCName("\\\\$server", $domain, \$temppdc)) {
         reportsyserror($server, Win32::Lanman::GetLastError(), "could not retrieve domain controller info");
         return($temppdc);
      }
   }

   $temppdc =~ s/\\//g;
   $temppdc = lc($temppdc);

   if ($temppdc =~ /\S+/) {
      return($temppdc);
   } else {
      return($temppdc);
   }
}

####################################################################
# Retrieve the server type
#
#
#
#
#
#
#
####################################################################

sub get_server_type ($$) {
   my ($server, $identstring) = @_;
   my ($remKey);

   if (lc($server) eq $pdcname) {
      return ("Primary Domain Controller");
   }

   if ($identstring =~ /Lanman/ || $identstring =~ /Backup/ ) {
      return ("Backup Domain Controller");
   }

   if ($identstring =~ /Server/) {
      return ("Server");
   }

   if ($identstring =~ /Work/ || $identstring =~ /Professional/ ) {
      return ("Workstation");
   }

   if ($identstring =~ /WinNT/) {
      return ("Workstation");
   }

   return ("(Unknown System Type)");
}

####################################################################
# Determine several OS Parameters:
#
# Accepts: servername
#
# Returns: os version
#          os service pack
#          os architecture
#          os string
#          os systemroot
#          os partition
#
# The WMI routines are originally from Microsoft's Scripting
# Guide (Scriptomatic) available at
# http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
#
####################################################################

# Determine Architecture

# this is only for reference, as it will only report the architecture of a local system
#
# The $^O variable and the $Config{'archname'} values for various DOSish perls are as follows:
#
#    OS            $^O        $Config{'archname'}
#    --------------------------------------------
#    MS-DOS        dos
#    PC-DOS        dos
#    OS/2          os2
#    Windows 95    MSWin32    MSWin32-x86
#    Windows NT    MSWin32    MSWin32-x86
#    Windows NT    MSWin32    MSWin32-alpha
#    Windows NT    MSWin32    MSWin32-ppc
#
#    print "Architecture: $Config{'archname'}\n";

sub get_os_version ($) {
   my ($server) = @_;
   # Set these variables to zero, just in case there's an issue getting the data
   my ($osVersion, $osServicePack, $osArchitecture, $osString, $osSystemRoot, $osPartition, $osInstallDate) = 0;

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my (@computers) = $server;

   foreach my $computer (@computers) {
      my ($objWMIService) = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_OperatingSystem","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            #reporttext("\tBootDevice: $objItem->{BootDevice}\n");
            #reporttext("\tBuildNumber: $objItem->{BuildNumber}\n");
            #reporttext("\tBuildType: $objItem->{BuildType}\n");
            #reporttext("\tCaption: $objItem->{Caption}\n");
            #reporttext("\tCodeSet: $objItem->{CodeSet}\n");
            #reporttext("\tCountryCode: $objItem->{CountryCode}\n");
            #reporttext("\tCreationClassName: $objItem->{CreationClassName}\n");
            #reporttext("\tCSCreationClassName: $objItem->{CSCreationClassName}\n");
            #reporttext("\tCSDVersion: $objItem->{CSDVersion}\n");
            #reporttext("\tCSName: $objItem->{CSName}\n");
            #reporttext("\tCurrentTimeZone: $objItem->{CurrentTimeZone}\n");
            #reporttext("\tDataExecutionPrevention_32BitApplications: $objItem->{DataExecutionPrevention_32BitApplications}\n");
            #reporttext("\tDataExecutionPrevention_Available: $objItem->{DataExecutionPrevention_Available}\n");
            #reporttext("\tDataExecutionPrevention_Drivers: $objItem->{DataExecutionPrevention_Drivers}\n");
            #reporttext("\tDataExecutionPrevention_SupportPolicy: $objItem->{DataExecutionPrevention_SupportPolicy}\n");
            #reporttext("\tDebug: $objItem->{Debug}\n");
            #reporttext("\tDescription: $objItem->{Description}\n");
            #reporttext("\tDistributed: $objItem->{Distributed}\n");
            #reporttext("\tEncryptionLevel: $objItem->{EncryptionLevel}\n");
            #reporttext("\tForegroundApplicationBoost: $objItem->{ForegroundApplicationBoost}\n");
            #reporttext("\tFreePhysicalMemory: $objItem->{FreePhysicalMemory}\n");
            #reporttext("\tFreeSpaceInPagingFiles: $objItem->{FreeSpaceInPagingFiles}\n");
            #reporttext("\tFreeVirtualMemory: $objItem->{FreeVirtualMemory}\n");

            # OS Install Date
            $osInstallDate = $objItem->{InstallDate};

            #                            abcdefghijklmnopqrstuvwxy
            # format for Time Generated: 20060513175156.000000-240
            my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = split(//,$objItem->{InstallDate});
            my ($year) = $a.$b.$c.$d;
            my ($month) = $e.$f;
            my ($day) = $g.$h;
            my ($hour) = $i.$j;
            my ($min) = $k.$l;
            my ($sec) = $m.$n;
            $osInstallDate = "$year-$month-$day";
            reportdebug("osInstallDate: $osInstallDate");

            #reporttext("\tInstallDate: $objItem->{InstallDate}\n");
            #reporttext("\tLargeSystemCache: $objItem->{LargeSystemCache}\n");
            #reporttext("\tLastBootUpTime: $objItem->{LastBootUpTime}\n");
            #reporttext("\tLocalDateTime: $objItem->{LocalDateTime}\n");
            #reporttext("\tLocale: $objItem->{Locale}\n");
            #reporttext("\tManufacturer: $objItem->{Manufacturer}\n");
            #reporttext("\tMaxNumberOfProcesses: $objItem->{MaxNumberOfProcesses}\n");
            #reporttext("\tMaxProcessMemorySize: $objItem->{MaxProcessMemorySize}\n");

            # OS String, SystemRoot and Partition
            ($osString, $osSystemRoot, $osPartition) = split(/\|/, $objItem->{Name});
            reportdebug("osString: $osString");
            reportdebug("osSystemRoot: $osSystemRoot");
            reportdebug("osPartition: $osPartition");
            # reporttext("\tName: $objItem->{Name}\n");
            #reporttext("\tNumberOfLicensedUsers: $objItem->{NumberOfLicensedUsers}\n");
            #reporttext("\tNumberOfProcesses: $objItem->{NumberOfProcesses}\n");
            #reporttext("\tNumberOfUsers: $objItem->{NumberOfUsers}\n");
            #reporttext("\tOrganization: $objItem->{Organization}\n");
            #reporttext("\tOSLanguage: $objItem->{OSLanguage}\n");
            #reporttext("\tOSProductSuite: $objItem->{OSProductSuite}\n");
            #reporttext("\tOSType: $objItem->{OSType}\n");
            #reporttext("\tOtherTypeDescription: $objItem->{OtherTypeDescription}\n");
            #reporttext("\tPlusProductID: $objItem->{PlusProductID}\n");
            #reporttext("\tPlusVersionNumber: $objItem->{PlusVersionNumber}\n");
            #reporttext("\tPrimary: $objItem->{Primary}\n");
            #reporttext("\tProductType: $objItem->{ProductType}\n");
            #reporttext("\tQuantumLength: $objItem->{QuantumLength}\n");
            #reporttext("\tQuantumType: $objItem->{QuantumType}\n");
            #reporttext("\tRegisteredUser: $objItem->{RegisteredUser}\n");
            #reporttext("\tSerialNumber: $objItem->{SerialNumber}\n");

            # Service Pack
            $osServicePack = ($objItem->{ServicePackMajorVersion});

            #reporttext("\tServicePackMajorVersion: $objItem->{ServicePackMajorVersion}\n");
            #reporttext("\tServicePackMinorVersion: $objItem->{ServicePackMinorVersion}\n");
            #reporttext("\tSizeStoredInPagingFiles: $objItem->{SizeStoredInPagingFiles}\n");
            #reporttext("\tStatus: $objItem->{Status}\n");
            #reporttext("\tSuiteMask: $objItem->{SuiteMask}\n");
            #reporttext("\tSystemDevice: $objItem->{SystemDevice}\n");
            #reporttext("\tSystemDirectory: $objItem->{SystemDirectory}\n");
            #reporttext("\tSystemDrive: $objItem->{SystemDrive}\n");
            #reporttext("\tTotalSwapSpaceSize: $objItem->{TotalSwapSpaceSize}\n");
            #reporttext("\tTotalVirtualMemorySize: $objItem->{TotalVirtualMemorySize}\n");
            #reporttext("\tTotalVisibleMemorySize: $objItem->{TotalVisibleMemorySize}\n");

            # OS Version
            my ($osVersionPrimary, $osVersionSecondary) = split(/\./, $objItem->{Version});
            $osVersion = "$osVersionPrimary.$osVersionSecondary";
            reportdebug("osVersion: $osVersion");

            #reporttext("\tVersion: $objItem->{Version}\n");
            #reporttext("\tWindowsDirectory: $objItem->{WindowsDirectory}\n");
            #reporttext("\n");
         }
      }
   }

   foreach my $computer (@computers) {
      my ($objWMIService) = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Processor", "WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            #reporttext("\tAddressWidth: $objItem->{AddressWidth}\n");
            #reporttext("\tArchitecture: $objItem->{Architecture}\n");
            #reporttext("\tAvailability: $objItem->{Availability}\n");
            #reporttext("\tCaption: $objItem->{Caption}\n");
            #reporttext("\tConfigManagerErrorCode: $objItem->{ConfigManagerErrorCode}\n");
            #reporttext("\tConfigManagerUserConfig: $objItem->{ConfigManagerUserConfig}\n");
            #reporttext("\tCpuStatus: $objItem->{CpuStatus}\n");
            #reporttext("\tCreationClassName: $objItem->{CreationClassName}\n");
            #reporttext("\tCurrentClockSpeed: $objItem->{CurrentClockSpeed}\n");
            #reporttext("\tCurrentVoltage: $objItem->{CurrentVoltage}\n");
            #reporttext("\tDataWidth: $objItem->{DataWidth}\n");

            # OS Architecture
            ($osArchitecture) = split(/ /, $objItem->{Description});
            reportdebug("osArchitecture: $osArchitecture");

            #reporttext("\tDescription: $objItem->{Description}\n");
            #reporttext("\tDeviceID: $objItem->{DeviceID}\n");
            #reporttext("\tErrorCleared: $objItem->{ErrorCleared}\n");
            #reporttext("\tErrorDescription: $objItem->{ErrorDescription}\n");
            #reporttext("\tExtClock: $objItem->{ExtClock}\n");
            #reporttext("\tFamily: $objItem->{Family}\n");
            #reporttext("\tInstallDate: $objItem->{InstallDate}\n");
            #reporttext("\tL2CacheSize: $objItem->{L2CacheSize}\n");
            #reporttext("\tL2CacheSpeed: $objItem->{L2CacheSpeed}\n");
            #reporttext("\tLastErrorCode: $objItem->{LastErrorCode}\n");
            #reporttext("\tLevel: $objItem->{Level}\n");
            #reporttext("\tLoadPercentage: $objItem->{LoadPercentage}\n");
            #reporttext("\tManufacturer: $objItem->{Manufacturer}\n");
            #reporttext("\tMaxClockSpeed: $objItem->{MaxClockSpeed}\n");
            #reporttext("\tName: $objItem->{Name}\n");
            #reporttext("\tOtherFamilyDescription: $objItem->{OtherFamilyDescription}\n");
            #reporttext("\tPNPDeviceID: $objItem->{PNPDeviceID}\n");
            #reporttext("\tPowerManagementCapabilities: " . join(",", (in $objItem->{PowerManagementCapabilities})) . "\n");
            #reporttext("\tPowerManagementSupported: $objItem->{PowerManagementSupported}\n");
            #reporttext("\tProcessorId: $objItem->{ProcessorId}\n");
            #reporttext("\tProcessorType: $objItem->{ProcessorType}\n");
            #reporttext("\tRevision: $objItem->{Revision}\n");
            #reporttext("\tRole: $objItem->{Role}\n");
            #reporttext("\tSocketDesignation: $objItem->{SocketDesignation}\n");
            #reporttext("\tStatus: $objItem->{Status}\n");
            #reporttext("\tStatusInfo: $objItem->{StatusInfo}\n");
            #reporttext("\tStepping: $objItem->{Stepping}\n");
            #reporttext("\tSystemCreationClassName: $objItem->{SystemCreationClassName}\n");
            #reporttext("\tSystemName: $objItem->{SystemName}\n");
            #reporttext("\tUniqueId: $objItem->{UniqueId}\n");
            #reporttext("\tUpgradeMethod: $objItem->{UpgradeMethod}\n");
            #reporttext("\tVersion: $objItem->{Version}\n");
            #reporttext("\tVoltageCaps: $objItem->{VoltageCaps}\n");
            #reporttext("\n");
         }
      }
   }

   return ($osVersion, $osServicePack, $osArchitecture, $osString, $osSystemRoot, $osPartition, $osInstallDate);
}

#=-------------------- begin system logon routines ------------------------=#

####################################################################
# authenticate as user to account on workstation or in domain
#
#
#
#
#
#
#
####################################################################

sub logon_as_user ($$$$) {
   my ($domain, $server, $user, $password) = @_;

   if ($domain eq "") {
      $domain = $server;
   }

   my %useinfo = (
     type       => &RESOURCETYPE_ANY,
     remotename => "\\\\$server\\ipc\$",
     username   => "$domain\\$user",
     password   => "$password",
   );
   if (!Win32::Lanman::WNetAddConnection(\%useinfo)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "connection failed");
      return (-1);
   }
   reportdebug(Win32::AdminMisc::GetLogonName());

   return (0);
}

# use Win32::NetResource qw(:DEFAULT GetSharedResources GetError AddConnection);
# use Win32;
#
# # Add the connection
# if (AddConnection({'RemoteName' => "$share"}, $Password, "$Compname\\$Username", $Connection )) {
#    print "Connection to $share achieved\r\n";
#  } else {
#    print "Could not connect to $share : $!";
#    $error = Win32::GetLastError();
#    $format_error = Win32::FormatMessage($error);
#    print $error." : ".$format_error."\r\n\r\n";
#  }


# use Win32::Lanman;
# my %useinfo = (
#         type            => &RESOURCETYPE_ANY,
#         remotename      => '\\\\remotemachine\\ipc$',
#         username        => 'domain\\username',
#         password        => 'userpassword',
# );
# my $result = Win32::Lanman::WNetAddConnection(\%useinfo);


#=------------- begin policy checking routines -------------------=#

####################################################################
#
# Description: check audit logging policy
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub audit_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (%info, $options, $failures);

   if (!Win32::Lanman::LsaQueryAuditEventsPolicy("\\\\$server", \%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "audit policy connection failed");
      return();
   }

   $options = $info{eventauditingoptions};

   #print "auditingmode=$info{auditingmode}\n";
   #print "maximumauditeventcount=$info{maximumauditeventcount}\n";
   #print "eventauditingoptions:\n" if($info{maximumauditeventcount} > 0)
   #foreach my $option (@$options) {
   #   print "\t$option\n";
   #}

   if (@$options[0] < $restart_shutdown_system) {
      reportfail($server, "Restart and Shutdown audit policy set for $auditpol[@$options[0]]. Should be $auditpol[$restart_shutdown_system]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tRestart and Shutdown audit policy set for $auditpol[@$options[0]]\n");
   }

   if (@$options[1] < $logon_logoff) {
      reportfail($server, "Logon and Logoff set for $auditpol[@$options[1]]. Should be $auditpol[$logon_logoff]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tLogon and Logoff set for $auditpol[@$options[1]]\n");
   }

   if (@$options[2] < $file_object_access) {
      reportfail($server, "File and Object Access set for $auditpol[@$options[2]]. Should be $auditpol[$file_object_access]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tFile and Object Access set for $auditpol[@$options[2]]\n");
   }

   if (@$options[3] < $user_rights_use) {
      reportfail($server, "Use of User Rights set for $auditpol[@$options[3]]. Should be $auditpol[$user_rights_use]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tUse of User Rights set for $auditpol[@$options[3]]\n");
   }

   if (@$options[4] < $process_tracking) {
      reportfail($server, "Process Tracking set for $auditpol[@$options[4]]. Should be $auditpol[$process_tracking]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tProcess Tracking set for $auditpol[@$options[4]]\n");
   }

   if (@$options[5] < $security_policy_changes) {
      reportfail($server, "Security and Policy Changes set for $auditpol[@$options[5]]. Should be $auditpol[$security_policy_changes]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tSecurity and Policy Changes set for $auditpol[@$options[5]]\n");
   }

   if (@$options[6] < $user_group_management) {
      reportfail($server, "User and Group Management set for $auditpol[@$options[6]]. Should be $auditpol[$user_group_management]");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tUser and Group Management set for $auditpol[@$options[6]]\n");
   }

   if ( $osversion >= 5 ) {
      if (@$options[7] < $directory_service_access) {
         reportfail($server, "Directory Service Access set for $auditpol[@$options[7]]. Should be $auditpol[$directory_service_access]");
         $failures++;
      } elsif ($verbose) {
         reporttext("\tDirectory Service Access set for $auditpol[@$options[6]]\n");
      }
   }

   if (!$failures) {
      reporttext("\tEvent Auditing set correctly\n");
   }

   return();
}

####################################################################
#
# Description: check if guest account is disabled
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub guest_account_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;

   my $guest_test = &account_is_disabled($server, $guestid);

   if ($guest_test == 1) {
      reporttext("\t$guestid account is disabled\n");
   } elsif ($guest_test == 0) {
      reportfail($server, "$guestid account is enabled");
   } else {
      reporterror($server, "could not get information for guest account ($guestid)");
   }

   return();
}

####################################################################
#
# Description: check guest accounts for group privledges outside of Guests
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub guest_group_account_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@List, @Groups, @Group);
   my ($IUSR) = "iusr_"."$server";
   my ($VUSR) = "vusr_"."$server";
   my (@CheckFor) = ("$IUSR", "$VUSR", "TsInternetUser", "Guest", "Replicate");
   my ($accountid);
   my (@validGroups) = ("Domain Guests", "Guests");
   my ($count);

   if (!Win32::NetAdmin::GetUsers("\\\\$server", "", \@List )) {
      reportsyserror($server, Win32::NetAdmin::GetError(), "GetUsers returned an error for $accountid");
      return();
   }

   foreach $accountid (@List) {
      reportdebug("AccountID: $accountid");
      if (grep {/$accountid/i} @CheckFor) {
         reportdebug("$accountid matches @CheckFor");
      if (!Win32::Lanman::NetUserGetLocalGroups("\\\\$server", $accountid, '', \@Groups)) {
            reportsyserror($server, Win32::Lanman::GetLastError(), "NetUserGetLocalGroups returned an error for $accountid");
            return();
         }
         foreach my $Group (@Groups) {
            foreach my $grp ( @validGroups ) {
               reportdebug("grp: $grp \t Group{name}: ${$Group}{'name'}");
               if ( $grp !~ ${$Group}{'name'} && $count == 0 ) {
                  reportfail($server, "$accountid account belongs to group: ${$Group}{'name'}");
                  $count++;
               }
            }
            $count = 0;
         }
      }
   }

   return();
}

####################################################################
#
# Description: check if account is disabled
#
# Accepts: server
#          username
#
# Returns: -1 if there was an error
#           0 if account is enabled
#           1 if account is disabled
#
####################################################################

sub account_is_disabled ($$) {
   my ($server, $accountid) = @_;
   my (%info);

   if (!Win32::Lanman::NetUserGetInfo("\\\\$server", $accountid, \%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "NetUserGetInfo could not retrieve user information for $accountid");
      return (-1);
   }

   my $test = $info{'flags'} & UF_ACCOUNTDISABLE();
   reportdebug("account is disabled -> $test");

   if ($test != 2) {
      return (0);
   } else {
      return (1);
   }
}

####################################################################
#
# Description: check if account password is stored with reversible encryption
#
# Accepts: username
#          server
#          osversion
#          osservicepack
#          osarch
#
# Returns: -1 if there was an error
#           0 if false
#           1 if true
#
####################################################################

# It is using the NetUserEnum MS api with a buffer defined type of  USER_INFO_3, and checks
# for the UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED flag which according to MS web page states
# that this represents whether : The user's password is stored under reversible encryption
# in the Active Directory.  For Windows NT:  This value is not supported.

sub account_password_is_encrypted ($$$$) {
   my ($accountid, $server, $osversion, $osservicepack, $osarch) = @_;
   my (%info);
   my ($test);

   if (!Win32::Lanman::NetUserGetInfo("\\\\$server", $accountid, \%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "NetUserGetInfo could not retrieve user information for $accountid");
      return (-1);
   }

   # function not supported on Windows NT 4

   if ($osversion > 4) {
      $test = $info{'flags'} & UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED();
      reportdebug("encrypted text password enabled -> $test");
       if ($info{'flags'} & UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED()) {
         reportfail($server, "Account $accountid -> Encrypted text password is enabled");
       } else {
         reporttext("\tAccount $accountid -> Encrypted text password is disabled\n");
       }

      foreach my $key(sort keys %info) {
         reportdebug("$key=$info{$key}");
      }
      reportdebug("\n");
   } else {
      reporttext("\tThis feature is not supported on Windows NT $osversion\n");
   }

   if ($test == 0) {
      return (0);
   } else {
      return (1);
   }

   return();
}

####################################################################
#
# Description: check if account password set to 'password never expires'
#
# Accepts: server
#          username
#
# Returns: -1 if there was an error
#           0 if the password expires
#           1 if the password never expires
#
####################################################################

sub password_never_expires ($$) {
   my ($server, $accountid) = @_;
   my (%info);

   if (!Win32::Lanman::NetUserGetInfo("\\\\$server",$accountid,\%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "unable to retrieve user information for $accountid");
      return (-1);
   }

   my $test = $info{'flags'} & UF_DONT_EXPIRE_PASSWD();

   if ($test != 0) {
      return (1);
   } else {
      return (0);
   }
}

####################################################################
#
# Description: list all account information from a system/domain
#
# Accepts: server
#          username
#
# Returns: nothing
#
####################################################################

sub list_all_accounts ($$) {
   my ($server, $accountid) = @_;
   my (%info);
   my (@List);
   my (@pwage);
   my ($pwagedays);

   if (!Win32::NetAdmin::GetUsers("\\\\$server", "", \@List )) {
      reportsyserror($server, Win32::NetAdmin::GetError(), "unable to gather user listing from server");
      return();
   }

   foreach $accountid (@List) {
      if (!Win32::Lanman::NetUserGetInfo("\\\\$server",$accountid,\%info)) {
         reportsyserror($server, Win32::Lanman::GetLastError(), "NetUserGetInfo unable to retrieve user information for $accountid");
      } else {
         @pwage = split(/\./, $info{'password_age'});
         $pwagedays = int($pwage[0] / (3600*24));
         reporttext("\n");
         reporttext("\tName        => $info{'name'}\n");
         reporttext("\tComment     => $info{'comment'}\n");
         reporttext("\tUID         => $info{'user_id'}\n");
         reporttext("\tPasswd Age  => $pwagedays\n");
         reporttext("\tLast Logon  => ".localtime($info{'last_logon'})."\n");
         reporttext("\tLast Logoff => ".localtime($info{'last_logoff'})."\n");
         reporttext("\tAccount does not expire\n") if ($info{'acct_expires'} == -1);
         reporttext("\tAccount is disabled\n") if ($info{'flags'} & UF_ACCOUNTDISABLE());
         reporttext("\tUser cannot change password\n") if ($info{'flags'} & UF_PASSWD_CANT_CHANGE());
         reporttext("\tAccount is locked out\n") if ($info{'flags'} & UF_LOCKOUT());
         reporttext("\tPassword does not expire\n") if ($info{'flags'} & UF_DONT_EXPIRE_PASSWD());
         reporttext("\tPassword not required\n") if ($info{'flags'} & UF_PASSWD_NOTREQD());
         reporttext("\n");
      }
   }

   return ();
}

####################################################################
#
# Description: check account password policy
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub password_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($failures, %info);
   my ($tmpval);

   if (!Win32::Lanman::NetUserModalsGet("\\\\$server", \%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "unable to check password policy because NetUserModalsGet failed");
      return();
   }
   if (!scalar(%info)) {
      reporterror($server, "unable to check password policy because NetUserModalsGet returned no information");
      return();
   }

   if ($debug) {
      my @keys = keys (%info);
         foreach my $key (@keys) {
            reporttext("password_policy -> $key=$info{$key}\n");
         }
   }

   $tmpval = $info{min_passwd_age} / 86400;
   if ($tmpval < $min_passwd_age) {
      reportfail($server, "Minimum password age = $tmpval days. Should be $min_passwd_age");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tMinimum password age = $tmpval\n");
   }

   $tmpval = $info{max_passwd_age} / 86400;
   if ($tmpval > $max_passwd_age) {
      reportfail($server, "Maximum password age = $tmpval days. Should be a maximum of $max_passwd_age");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tMaximum password age = $tmpval days\n");
   }

   $tmpval = $info{min_passwd_len};
   if ($tmpval < $min_passwd_len) {
      reportfail($server, "Minimum password length = $tmpval. Should be a minimum of $min_passwd_len");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tMinimum password length = $tmpval\n");
   }

   $tmpval = $info{password_hist_len};
   if ($tmpval < $password_hist_len) {
      reportfail($server, "Password Uniqueness set to remember $tmpval passwords. Should be a minimum of $password_hist_len");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tPassword Uniqueness set to remember $tmpval passwords\n");
   }

   if (!$failures) {
      reporttext("\tUser Account Policy is set correctly\n");
   }

   return();
}

####################################################################
#
# Description: check account lockout policy
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub account_lockout_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($failures, %info);
   my ($tmpval);

   if (!Win32::Lanman::NetUserModalsGet("\\\\$server", \%info)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "unable to check password policy because NetUserModalsGet failed");
      return();
   }
   if (!scalar(%info)) {
      reporterror($server, "unable to check account lockout policy because NetUserModalsGet returned no information");
      return();
   }

   if ($debug) {
      my @keys = keys (%info);
         foreach my $key (@keys) {
            reporttext("account lockout policy -> $key=$info{$key}\n");
         }
   }

   $tmpval = $info{'lockout_threshold'};
   if ($tmpval > $lockout_threshold) {
      reportfail($server, "Account lockout after $tmpval attempts. Should be a maximum of $lockout_threshold");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tAccount lockout after $tmpval attempts\n");
   }

   $tmpval = $info{'lockout_observation_window'} / 60;
   if ($tmpval < $lockout_observation_window) {
      reportfail($server, "Account lockout reset count after $tmpval minutes. Should be a minimum of $lockout_observation_window");
      $failures++;
   } elsif ($verbose) {
      reporttext("\tAccount lockout reset count after $tmpval minutes\n");
   }

   $tmpval = $info{'lockout_duration'} / 60;

   if ($info{'lockout_duration'} != -1 && $tmpval != $lockout_duration) {
      if ($lockout_duration == -1) {
         reportfail($server, "Account lockout duration is $tmpval minutes. Should be forever (-1)");
      } else {
         reportfail($server, "Account lockout duration is $tmpval minutes. Should be minimum of $lockout_duration");
      }
      $failures++;
   } elsif ($verbose) {
      if ($info{'lockout_duration'} == -1) {
         reporttext("\tAccount lockout duration is forever (-1)\n");
      } else {
         reporttext("\tAccount lockout duration is $tmpval minutes\n");
      }
   }

   if (!$failures) {
      reporttext("\tAccount lockout policy is set correctly\n");
   }

   return();
}

####################################################################
#
# Description: checks service accounts to determine what type
#              of account is being used.  if the user has created
#              their own service account(s), then it is checked to
#              verify that the account status is set to Disabled.
#              this helps with keeping accounts from being usable
#              if the service was hacked.
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
# The WMI routines are originally from Microsoft's Scripting
# Guide (Scriptomatic) available at
# http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
#
####################################################################

sub service_account_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($accounts, @services);
   my ($account_name, $service_name);
   my ($account);

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my @computers = ($server);

   foreach my $computer (@computers) {
      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      } else {
         foreach my $computer (@computers) {
            my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Service", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
            foreach my $objItem (in $colItems) {
               #reporttext("\tAcceptPause: $objItem->{AcceptPause}\n");
               #reporttext("\tAcceptStop: $objItem->{AcceptStop}\n");
               reporttext("\tService Name: $objItem->{Caption}\n");
               my ($caption) = $objItem->{Caption};
               #reporttext("\tCheckPoint: $objItem->{CheckPoint}\n");
               #reporttext("\tCreationClassName: $objItem->{CreationClassName}\n");
               my ($description) = $objItem->{Description};
               if ($caption ne $description && $description ne '') {
                  reporttext("\tDescription: $objItem->{Description}\n");
               }
               #reporttext("\tDesktopInteract: $objItem->{DesktopInteract}\n");
               #reporttext("\tDisplayName: $objItem->{DisplayName}\n");
               #reporttext("\tErrorControl: $objItem->{ErrorControl}\n");
               #reporttext("\tExitCode: $objItem->{ExitCode}\n");
               #reporttext("\tInstallDate: $objItem->{InstallDate}\n");
               #reporttext("\tName: $objItem->{Name}\n");
               reporttext("\tPathName: $objItem->{PathName}\n");
               reporttext("\tProcessId: $objItem->{ProcessId}\n");
               #reporttext("\tServiceSpecificExitCode: $objItem->{ServiceSpecificExitCode}\n");
               #reporttext("\tServiceType: $objItem->{ServiceType}\n");
               reporttext("\tStarted: $objItem->{Started}\n");
               reporttext("\tStartMode: $objItem->{StartMode}\n");
               # service type
               #reporttext("\tStartName: $objItem->{StartName}\n");
               #reporttext("\tState: $objItem->{State}\n");
               reporttext("\tStatus: $objItem->{Status}\n");
               #reporttext("\tSystemCreationClassName: $objItem->{SystemCreationClassName}\n");
               #reporttext("\tSystemName: $objItem->{SystemName}\n");
               #reporttext("\tTagId: $objItem->{TagId}\n");
               #reporttext("\tWaitHint: $objItem->{WaitHint}\n");
               #reporttext("\n");

               $account_name = $objItem->{StartName};
               $service_name = $objItem->{Name};

               $account = 0;

               foreach my $name ( @ms_service_account_names ) {
                  #if ($name =~ m/\Q$account_name\E$/i ) {
                  if (grep {/$name/i} $account_name) {
                     reportdebug("name -> $name, account_name -> $account_name");
                  $account++;
                  }
               }

               my($workgroup, $account_name_temp) = split(/\\/, $account_name);
               reportdebug("account_name_temp -> $account_name_temp");

                  # List of excluded users from this check
                  my ($IUSR) = "iusr_"."$server";
                  my ($IWAM) = "iwam_"."$server";
                  my ($VUSR) = "vusr_"."$server";
                  my (@excludeUsers) = ("$IUSR",
                                        "$IWAM",
                                        "$VUSR",
                                        "TsInternetUser",
                                        "Replicate",
                                        "Guest"
                                       );

               if ($account > 0 || (grep {/$account_name_temp/i} @excludeUsers)) {
                  reporttext("\tService $service_name uses the $account_name account\n");
               } else {
                     my ($service_account_disabled_test) = &account_is_disabled($server, $account_name_temp);
                     reportdebug("service_account_disabled_test -> $service_account_disabled_test");
                     if ($service_account_disabled_test == 0) {
                        reportwarn($server, "Service $service_name uses account $account_name for Log On, which is Enabled");
                     } elsif ($service_account_disabled_test == 1) {
                        reporttext("\tService $service_name uses account $account_name for Log On which is disabled\n");
                     } else {
                        reporttext("\t$service_name uses $account_name which returned an error\n");
                     }
               }
               reporttext("\n");
            }
         }
      }
   }
}

####################################################################
#
# Description: display service names and their status
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub service_names_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my %list;
   my $key;
   my $srvformat = '%-40s : %-30s';

   if (!Win32::Service::GetServices($server, \%list)) {
      reportsyserror($server, Win32->GetLastError(), "GetServices failed for $server"); # %%%%FIXME
      return();
   }

   reporttext("\t" . sprintf($srvformat, "Display Name", "Service Name") . "\n");
   reporttext("\t" . sprintf($srvformat, "------------", "------------") . "\n");
   foreach $key (keys %list) {
      reporttext("\t" . sprintf($srvformat, $key, $list{$key}) . "\n");
   }
   reporttext("\n");

   return();
}

####################################################################
#
# Description: check messenger and alerter service status
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub critical_service_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@services, %critservice);

   if (!Win32::Lanman::EnumServicesStatus("\\\\$server", "", &SERVICE_WIN32, &SERVICE_STATE_ALL, \@services)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "unable to enumerate service status");
      return();
   }

   foreach my $service (@services) {
      if (${$service}{'name'} eq "Alerter" || ${$service}{'name'} eq "Messenger") {
         if (${$service}{'state'} != 4) { # FIXME: change 4 to symbolic constant or document possible values in comment
            reportwarn($server, "${$service}{name} service is not running");
         } elsif ($verbose) {
            reporttext("\t${$service}{name} service is installed and running\n");
         }
         $critservice{${$service}{'name'}} = 1;
      }
   }

   if (!$critservice{'Alerter'}) {
      reporterror($server, "Alerter service not installed");
   }

   if (!$critservice{'Messenger'}) {
      reporterror($server, "Messenger service not installed");
   }

   return();
}

####################################################################
#
# Description: check messenger service status
#
# Accepts: server
#          osversion
#          osservicepack
#
# Returns: nothing
#
####################################################################

sub messenger_status_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my %status;
   my $key;
   my $msgformat = '%-30s : %-20s';

   if (!Win32::Service::GetStatus('', 'Messenger', \%status)) {
      reportsyserror($server, Win32->GetLastError(), "GetStatus(Messenger) failed"); # %%%%FIXME # %%%%FIXME
      return();
   }

   reporttext("\t" . sprintf($msgformat, "Messenger", "Status") . "\n");
   reporttext("\t" . sprintf($msgformat, "---------", "------") . "\n");
   foreach $key (keys %status) {
      reporttext("\t" . sprintf($msgformat, $key, $status{$key}) . "\n");
   }
   reporttext("\n");

   return();
}

####################################################################
#
# Description: check whether users can logon locally
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub local_logon_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@sids, @infos, $logonpriv);

   if (!Win32::Lanman::LsaEnumerateAccountsWithUserRight("\\\\$server", &SE_INTERACTIVE_LOGON_NAME, \@sids)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "unable to enumerate accounts with local logon rights");
      return();
   }

   if (!Win32::Lanman::LsaLookupSids("\\\\$server", \@sids, \@infos)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "sid lookup failed");
      return();
   }

   $logonpriv = 0;
   foreach my $info (@infos) {
      if (${$info}{'name'} eq "Users") {
         reportwarn($server, "Users can log on locally"); # FIXME: should FAIL be a config option?
         $logonpriv = 1;
         last;
      }
   }

   if (!$logonpriv) {
      reporttext("\tUsers can not logon locally\n");
   }

   return();
}

####################################################################
#
# Description: check server type, os, service pack and hotfixes
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub server_hotfix_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($osname);

   # We do this once in the main loop for each server

   # Windows NT 3.5x -> 3.5, 3.51
   # Windows NT 4.0  -> 4.0
   # Windows 2000    -> 5.0
   # Windows XP      -> 5.1
   # Windows 2003    -> 5.2

   if ( $osversion =~ m/3\.5/ ) {
      $osname = "NT";
   }
   if ( $osversion =~ m/4\.0/ ) {
      $osname = "NT";
   }
   if ( $osversion =~ m/5\.0/ ) {
      $osname = "2000";
   }

   if ( $osversion =~ m/5\.1/ ) {
      $osname = "XP";
   }

   if ( $osversion =~ m/5\.2/ ) {
      $osname = "2003";
   }

   if ( $osversion =~ m/5\.3/ ) {
      $osname = "Vista";
   }

   reporttext("\tMicrosoft Windows $osname ($osversion) $servertype with Service Pack $osservicepack\n");

   # Generate hotfix list
   &get_hotfixes($server, $osversion, $osservicepack, $osarch);

   return();
}

####################################################################
#
# Description: retrieve hotfixes installed on system
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub get_hotfixes ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (%hotfixHash);
   my ($remKey);

   #if ($localonly) {
   #   $UncPath = "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\";
   #} else {
   #   $UncPath = "\\\\$server\\HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\";
   #}
   #$remKey = $Registry->{$UncPath};
   #
   #if (!$remKey) {
   #   reportsyserror($server, Win32->GetLastError(), "unable to retrieve installation date registry information");
   #} else {
   #   my $remDate = $remKey->GetValue("InstallDate");
   #   $remDate = hex($remDate);
   #   my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime($remDate);
   #   $year = 1900+$year;
   #   $month = 1+$month;
   #   reporttext("\tSystem Installation Date according to InstallDate registry value is: $year-$month-$day_of_month\n");
   #}

   # Report the installdate (global) from get_os_version routine
   if ($installdate) {
      reporttext("\tSystem Installation Date according to the Registry (via WMI) is: $installdate\n");
   }

   # Windows Registry

   reporttext("\tSearching for hotfixes in System Registry...\n");

   foreach my $location (@hotfix_registry_keys) {
      my (@hotfix_subkey_names);

      if ($localonly) {
         $UncPath = "$location";
      } else {
         $UncPath = "\\\\$server\\$location";
      }
      $remKey = $Registry->{$UncPath};

      if (!$remKey) {
         next;
      }

      @hotfix_subkey_names = $remKey->SubKeyNames;
      reportdebug("hotfix_subkey_names -> @hotfix_subkey_names");

      foreach my $knumber (@hotfix_subkey_names) {
         $knumber = ucfirst($knumber);
         my ($key) = $knumber;
         $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
         $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
         $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)/$2/i;

         reportdebug("knumber -> $knumber key -> $key");

         if ($localonly) {
            $UncPath = "$location\\$knumber";
         } else {
            $UncPath = "\\\\$server\\$location\\$knumber";
         }
         my ($remHFKey) = $Registry->{$UncPath};

         $hotfixHash{$key}{key} = $knumber;
         $hotfixHash{$key}{date} = "0000-00-00";
         $hotfixHash{$key}{time} = "00:00:00";
         $hotfixHash{$key}{status} = "Installed";
         if ( defined($hotfix{$knumber}) ) {
            $hotfixHash{$key}{description} = $hotfix{$knumber}; # from patchlist.txt
            reportdebug("$key description from patchlist.txt $hotfix{$knumber}");
         } else {
            my ($bestDesc);

            # remember previous value if we found it in another part of the registry
            if (defined($hotfixHash{$key}{description}) &&
                !($hotfixHash{$key}{description} =~ m/^NO_DESCRIPTION/)) { # FIXME: UNDO
               $bestDesc = $hotfixHash{$key}{description};
            } else {
               $bestDesc = "";
            }

            foreach my $descKey ("Description", "Fix Description", "Comments", "PackageName") {
               my ($regDesc) = $remHFKey->GetValue("$descKey");

               if (defined($regDesc) && length($regDesc) > length($bestDesc)) {
                  $bestDesc = $regDesc;
               }
            }

            if (length($bestDesc) > 0) {
               $hotfixHash{$key}{description} = $bestDesc;
               reportdebug("$key description from registry $bestDesc");
            } else {
               $hotfixHash{$key}{description} = "NO_DESCRIPTION_1"; # FIXME: UNDO
               reportdebug("$key description not found in registry");
            }
         }

         foreach my $dateKey (@hotfix_registry_keys_date_labels) {
            my ($ValueData) = $remHFKey->GetValue("$dateKey");

            if (defined($ValueData) && $ValueData ne "") {
               my ($ValueDate) = $ValueData;
               $ValueDate =~ s%([0-9]+)/([0-9]+)/([0-9]+)%$3-$1-$2%; # convert date format if it is different
               $ValueDate =~ s%-([1-9])-%-0$1-%; # zero-pad the month
               $ValueDate =~ s%-([1-9])$%-0$1%; # zero-pad the day
               $hotfixHash{$key}{date} = $ValueDate;
            } else { # FIXME: only do this after the loop if no date was found
               # If install date is not known, check the uninstall directory modification time
               my $sharename = "ADMIN\$";
               my $filename = "\\\\$server\\$sharename\\\$NtUninstall$knumber\$";

               # stat -> ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
               if ( (stat($filename))[9] ) {
                  # Get the modification time
                  my $mtime = (stat($filename))[9];

                  # Convert to legibile format
                  my ($seconds, $minutes, $hours, $day_of_month, $month, $year) = (localtime $mtime)[0..5];
                  $hotfixHash{$key}{date} = sprintf("%04d-%02d-%02d", 1900 + $year, 1 + $month, $day_of_month);
                  $hotfixHash{$key}{time} = sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
               }
            }
         }
      }
   }

   foreach my $key (sort keys %hotfixHash) {
      reportdebug("$key = ");
      reportdebug("hotfixHash{key} -> $hotfixHash{$key}{key} |");
      reportdebug("hotfixHash{date} -> $hotfixHash{$key}{date} |");
      reportdebug("hotfixHash{time} -> $hotfixHash{$key}{time} |");
      reportdebug("hotfixHash{status} -> $hotfixHash{$key}{status} |");
      reportdebug("hotfixHash{description} -> $hotfixHash{$key}{description}");
   }

   # IE Version Info

   my @ieValueList;
   my $ieTempKey=0;
   my $ieValueData;

   reporttext("\tSearching for IE version information in System Registry...\n");
   foreach my $location (@ie_version_registry_keys) {

      if ($localonly) {
         $UncPath = "$location";
      } else {
         $UncPath = "\\\\$server\\$location";
      }
      my $remKey = $Registry->{$UncPath};
      if (!defined($remKey) || $remKey eq "") {
         next;
      }
      foreach my $key (@ie_version_registry_key_labels) {
         if ( $ieValueData = $remKey->GetValue("$key") ) {
            push(@ieValueList, $ieValueData);
            #reporttext("\n\tMicrosoft IE Version in Registry is: $ieValueData\n");
         }
      }
   }

   foreach my $key (@ieValueList) {
      if ($key gt $ieTempKey) {
         $ieTempKey = $key; # FIXME: this value is never used
      }
   }
   reporttext("\tMicrosoft IE Version in Registry is: $ieValueData\n") if $ieValueData;

   # IE Patches

   reporttext("\tSearching for IE hotfixes in System Registry...\n");

   foreach my $location (@ie_hotfix_registry_keys) {
      if ($localonly) {
         $UncPath = "$location";
      } else {
         $UncPath = "\\\\$server\\$location";
      }
      $remKey = $Registry->{$UncPath};

      if (!$remKey) {
         reporttext("\tINFO: Could not find Registry key: $location\\MinorVersion\n");
      } else {
         my $ValueData = $remKey->GetValue("MinorVersion");
         reportdebug("$ValueData");
         my @ieHotfixArray = split(/;/, $ValueData);
         #foreach my $item ( @ieHotfixArray ) {
         #   reporttext("\t$item\n");
         #}

         foreach my $knumber (@ieHotfixArray) {
            # if there are multiple ';' separating the hotfixes, don't include blanks
            if ( $knumber eq "" ) { next; }

            $knumber = ucfirst($knumber);
            my ($key) = $knumber;
            $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
            $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
            $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?).*/$2/i;

            $hotfixHash{$key}{key}  = $knumber;
            $hotfixHash{$key}{date} = "0000-00-00"; # FIXME: no way at all to lookup date?
            $hotfixHash{$key}{time} = "00:00:00";
            $hotfixHash{$key}{status} = "Installed";
            if ( defined($hotfix{$knumber}) ) {
               $hotfixHash{$key}{description} = $hotfix{$knumber};
            } else {
               $hotfixHash{$key}{description} = "NO_DESCRIPTION_2"; # FIXME: UNDO
            }
         }
      }
   }

   foreach my $key (sort keys %hotfixHash) {
      reportdebug("$key = ");
      reportdebug("hotfixHash{key} -> $hotfixHash{$key}{key} |");
      reportdebug("hotfixHash{date} -> $hotfixHash{$key}{date} |");
      reportdebug("hotfixHash{time} -> $hotfixHash{$key}{time} |");
      reportdebug("hotfixHash{status} -> $hotfixHash{$key}{status} |");
      reportdebug("hotfixHash{description} -> $hotfixHash{$key}{description}");
   }

   # Windows Update - XML

   my ($SystemRootTemp);

   if ($localonly) {
      # don't convert to unc format
      $SystemRootTemp = $systemroot;
      # don't use; can't find all windows update files
      #$SystemRootTemp = substr($SystemRootTemp, 0, 2);
   } else {
      # set the systemroot and convert to unc format
      $systemroot =~ s/:/\$/;
      $SystemRootTemp = $systemroot;
      # don't use; can't find all windows update files
      #$SystemRootTemp = substr($SystemRootTemp, 0, 2);
   }

   reporttext("\tSearching for hotfixes in Windows Update History file(s)...\n");

   foreach my $location (@windows_update_files) {
      my ($pathstr);

      if ($localonly) {
         $pathstr = "$SystemRootTemp"."$location";
      } else {
         $pathstr = "\\\\$server\\$SystemRootTemp"."$location";
      }

      reportdebug("parsing update log: $location");

      my ($line, $contents);

      if ( $location =~ m/wuhistv3\.log/ ) {
         # the format is:
         # V3_2|5247|INSTALL|Security Update, February 13, 2002 (MSXML 3.0)|1,10,101,0|2005-05-21 22:10:33|1|SUCCESS|||
         # V3_2|5419|INSTALL|Q318138: Security Update (Windows NT 4.0)|1,10,101,0|2005-05-21 22:11:21|1|SUCCESS|||
         if ( -f $pathstr ) {
            reporttext("\tINFO: file $pathstr was found\n");

            my @loglines = read_file($pathstr);
            foreach my $item ( @loglines ) {
               if ( $item =~ m/[|]SUCCESS[|]/i ) {
                  my ($logVersion, $logKNumber, $logInstall, $logDescription, $logRevision, $logDateCombo) = split(/[|]/, $item);
                  my ($logDate, $logTime) = split(/\s+/, $logDateCombo);
                  my ($logCleanDesc) = $logDescription;
                  $logCleanDesc =~ s/ [A-Z][a-z]{2,8} (0?[1-9]|[1-3][0-9]),? [0-9]{4}/ /; # remove any dates which might look like KB numbers
                  my (@logArray) = split(/\s+/, $logCleanDesc);
                  foreach my $word ( @logArray ) {
                     my ($knumber) = ucfirst($word);
                     $knumber =~ s/:$//;
                     $knumber =~ s/\(//;
                     $knumber =~ s/\)//;
                     # look for KB numbers, or words ending with at least four digits
                     if ($knumber =~ m/^(KB|Wm|Q|M|S)[0-9]{3,}(v[1-9][0-9]*)?/i ||
                         $knumber =~ m/[0-9]{4,}(v[1-9][0-9]*)?$/) {
                        $logKNumber = $knumber;
                        reportdebug("WINDOWSV3-UPDATE-LOG: $logKNumber");
                     }
                  }

                  reportdebug("$logDate|$logTime|$logDescription|$logKNumber");

                  my ($key) = $logKNumber;
                  $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?).*/$2/i;
                  $hotfixHash{$key}{key} = $logKNumber;

                  if ( !defined($logDescription) || $logDescription eq "" ) {
                     if ( !defined($hotfixHash{$key}{description}) ) {
                        $hotfixHash{$key}{description} = "NO_DESCRIPTION_3"; # FIXME: UNDO
                     }
                  } else {
                     $hotfixHash{$key}{description} = $logDescription;
                  }
                  if ( !defined($hotfixHash{$key}{date}) || $hotfixHash{$key}{date} le $logDate ) {
                     $hotfixHash{$key}{date} = $logDate;
                     $hotfixHash{$key}{time} = $logTime;
                     $hotfixHash{$key}{status} = "Installed";
                  }
               }
            }
         } else {
            reporttext("\tINFO: file $pathstr was not found\n");
         }
      }

      if ( $location =~ m/iuhist\.xml/ ) {
         if ( -f $pathstr ) {
            # need to return Status Date Description Source KB/Q Number
            reporttext("\tINFO: file $pathstr was found\n");
            #my $wupdate = XMLin($pathstr, keyattr => ['itemStatus'], forcearray => 1, forcecontent => 1);
            #my $wupdate = XMLin($pathstr, keyattr => ['itemStatus'], forcecontent => 1);
            my $wupdate = XMLin($pathstr, keyattr => ['itemStatus']);

            #use Data::Dumper;
            #reporttext Dumper($wupdate);
            #
            #my $wupdate = \@wupdate;
            #for (my $i = 0; $i <= $#wupdate; $i++) {
            #   reporttext("\tDateTime: $wupdate->{itemStatus}->[$i]->{timestamp}\n");
            #}

            for (my $i = 0; $i <= $#{$wupdate->{itemStatus}}; $i++) {

               #reporttext("\tDateTime: $wupdate->{itemStatus}->[$i]->{timestamp}\n");
               #if ( $wupdate->{itemStatus}->[$i]->{installStatus}->{value} eq "" ) {
               #   reporttext("\tInstallStatus: FAILED\n");
               #} else {
               #   reporttext("\tInstallStatus: $wupdate->{itemStatus}->[$i]->{installStatus}->{value}\n");
               #}

               # Example Output:
               # DateTime: 2005-02-21T18:42:08
               # InstallStatus: COMPLETE
               # Identifier: 885834_W2K_SP5_WinSE_137723
               # Description: Security Update for Windows 2000 (KB885834)

               my ($DateXML, $TimeXML) = split(/T/, $wupdate->{itemStatus}->[$i]->{timestamp});
               my ($InstallStatusXML) = $wupdate->{itemStatus}->[$i]->{installStatus}->{value};
               my ($IdentifierXML) = $wupdate->{itemStatus}->[$i]->{identity}->{name};
               my ($DescriptionXML) = $wupdate->{itemStatus}->[$i]->{description}->{descriptionText}->{title};

               if ( !defined($InstallStatusXML) ) {
                  reporttext("\tBUG: unknown install status for $IdentifierXML ($DescriptionXML)\n"); # FIXME: why does this happen only for the WM9 codec package?
                  # unknown install status for WM_Codec_Installer_5914 (Windows Media 9 Series Codec Install Package)
                  # The XML looks ok, and is the same as for other items... Perl XML bug?
                  $InstallStatusXML = "unspecified";
               }

               reportdebug("XML: Date -> $DateXML | Time -> $TimeXML | InstallStatusXML -> $InstallStatusXML | IdentifierXML -> $IdentifierXML | DescriptionXML -> $DescriptionXML");
               reportdebug("XML: Identifier: $wupdate->{itemStatus}->[$i]->{identity}->{name}");
               reportdebug("XML: Description: $wupdate->{itemStatus}->[$i]->{description}->{descriptionText}->{title}");

               # keyword for status is COMPLETE or FAILED, we should only be reporting on patches which complete install

               if ( $InstallStatusXML =~ m/^COMPLETE$/ ) {
                  my ($knumXMLDescription);
                  if ($DescriptionXML =~ m/[(](KB|Wm|Q|M|S)?[0-9]{3,}[^ )]*[)]/i) { # handle (BLAH8888BLAH) format
                     $knumXMLDescription = $DescriptionXML;
                     $knumXMLDescription =~ s/.*[(]((KB|Wm|Q|M|S)?[0-9]{3,}[^ )]*)[)].*/$1/i;
                  } elsif ($DescriptionXML =~ m/^(KB|Wm|Q|M|S)?[0-9]{3,}(v[1-9][0-9]*)?:/i) { # handle ^BLAH8888BLAH: format
                     $knumXMLDescription = $DescriptionXML;
                     $knumXMLDescription =~ s/^((KB|Wm|Q|M|S)?[0-9]{3,}(v[1-9][0-9]*)?):.*$/$1/i;
                  } elsif ($DescriptionXML =~ m/\s+(KB|Wm|Q|M|S)?[1-9][0-9]{4,}(v[1-9][0-9]*)?$/i) { # handle BLAH8888$ format
                     $knumXMLDescription = $DescriptionXML;
                     $knumXMLDescription =~ s/\s+((KB|Wm|Q|M|S)?[1-9][0-9]{4,}(v[1-9][0-9]*)?)$/$1/i;
                  } else {
                     $knumXMLDescription = "";
                  }
                  reportdebug("XML: DescriptionXML -> $DescriptionXML");
                  reportdebug("XML: knumXMLDescription -> $knumXMLDescription");

                  my $key;

                  if ($knumXMLDescription ne "") {
                     $key = ucfirst($knumXMLDescription);
                  } else {
                     $key = ucfirst($IdentifierXML);
                  }
                  $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?).*/$2/i;
                  $hotfixHash{$key}{key} = $IdentifierXML;

                  reportdebug("XML: key -> $key IdentifierXML -> $IdentifierXML");

                  if ( !defined($DescriptionXML) || $DescriptionXML eq "" ) {
                     if ( !defined($hotfixHash{$key}{description}) ) {
                         $hotfixHash{$key}{description} = "NO_DESCRIPTION_4"; # FIXME: UNDO
                     }
                  } else {
                     $hotfixHash{$key}{description} = $DescriptionXML;
                  }

                  if ( !defined($hotfixHash{$key}{date}) || $hotfixHash{$key}{date} eq "" ) {
                     $hotfixHash{$key}{date} = "0000-00-00";
                  } else {
                     reportdebug("XML-DUPLICATE: hotfixhash{key}{date} -> $hotfixHash{$key}{date} | DateXML -> $DateXML");
                  }

                  # if the date is less than new date, take the new information since it's more current
                  if ( $hotfixHash{$key}{date} lt $DateXML ) {
                     $hotfixHash{$key}{date} = $DateXML;
                     $hotfixHash{$key}{time} = $TimeXML;
                     $hotfixHash{$key}{status} = $InstallStatusXML;
                  } else {
                     if ( !defined($hotfixHash{$key}{time}) || $hotfixHash{$key}{time} eq "" ) {
                        $hotfixHash{$key}{time} = "00:00:00";
                     }
                     if ( !defined($hotfixHash{$key}{status}) || $hotfixHash{$key}{status} eq "" ) {
                        $hotfixHash{$key}{status} = "UNKNOWN";
                     }
                  }

                  reportdebug("XML-DUPLICATE: hotfixHash{key}{key} -> $hotfixHash{$key}{key} | hotfixHash{date} -> $hotfixHash{$key}{date} | date -> $DateXML | hotfixHash{time} -> $hotfixHash{$key}{time} | time -> $TimeXML | hotfixHash{status} -> $hotfixHash{$key}{status} | status -> $InstallStatusXML | hotfixHash{description} -> $hotfixHash{$key}{description} | description -> $DescriptionXML | count -> $i");
               }
            }
         } else {
            reporttext("\tINFO: file $pathstr was not found\n");
         }
      }

      if ( $location =~ m/WindowsUpdate\.log/ ) {
         # Looking for the following types of lines:
         # 2006-05-04      16:39:28         752    7ac     Report  REPORT EVENT: {FDB60484-8637-460F-B68A-8E6D2E2B3B12}    2006-05-04 16:39:23-0400        1       184     101     {3E1EE9BF-A5F6-4CD8-BF9F-310F4CFDBAD1}  101     0       WindowsUpdate   Success Content Install Installation successful and restart required for the following update: Update for Background Intelligent Transfer Service (BITS) 2.0 and WinHTTP 5.1 (KB842773)
         # Success	Content Install	Installation Successful: Windows successfully installed the following update: Windows Malicious Software Removal Tool - September 2005 (KB890830)
         if ( -f $pathstr ) {
            reporttext("\tINFO: file $pathstr was found\n");
            my ($count) = 0; # to give unique ids to hotfixes with unknown KB numbers
            my (@loglines) = read_file($pathstr);
            foreach my $item ( @loglines ) {
               if ($item =~ m/^(\s|\000)*$/) {
                   # 16bit Unicode handling apparently gets confused sometimes and sends us a first or last line with a NUL; skip it
                   next;
               }
               my ($logDate, $logTime, $logType) = (split(/\s+/, $item))[0,1,4];
               reportdebug("WINDOWS-UPDATE-LOG: checking line: $item  (date=$logDate time=$logTime type=$logType");
               if ($logType =~ m/^Report$/i &&
                   ($item =~ m/Windows successfully installed the following update:/i ||
                    $item =~ m/successful and restart required for the following update:/i )) {
                  my ($logDescription) = $item;
                  $logDescription =~ s/^.* the following update:\s*//;
                  my ($logCleanDesc) = $logDescription;
                  $logCleanDesc =~ s/ [A-Z][a-z]{2,8} (0?[1-9]|[1-3][0-9]),? [0-9]{4}/ /; # remove any dates which might look like KB numbers
                  my (@logArray) = split(/\s+/, $logCleanDesc);
                  my ($logKNumber) = "";

                  reportdebug("WINDOWS-UPDATE-LOG: checking description: $logDescription");
                  foreach my $word ( @logArray ) {
                     reportdebug("WINDOWS-UPDATE-LOG: checking word: $word");
                     my ($knumber) = ucfirst($word);
                     $knumber =~ s/:$//;
                     $knumber =~ s/\(//;
                     $knumber =~ s/\)//;
                     # look for KB numbers, or words ending with at least four digits
                     if ( $knumber =~ m/^(KB|Wm|Q|M|S)[0-9]{3,}/i ||
                          $knumber =~ m/[0-9]{4,}(v[1-9][0-9]*)?$/ ) {
                        $logKNumber = $knumber;
                        reportdebug("WINDOWS-UPDATE-LOG: using as KNumber: $logKNumber");
                     }
                  }

                  reportdebug("$logDate|$logTime|$logDescription|$logKNumber");

                  my $key = $logKNumber;
                  if ( $key eq "" ) {
                     $key = "0$count";
                     $count++;
                  }
                  $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
                  $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?).*/$2/i;
                  $hotfixHash{$key}{key} = $key;

                  if ( !defined($logDescription) || $logDescription eq "" ) {
                     if ( !defined($hotfixHash{$key}{description}) ) {
                        $hotfixHash{$key}{description} = "NO_DESCRIPTION_5"; # FIXME: UNDO
                     }
                  } else {
                     $hotfixHash{$key}{description} = $logDescription;
                  }

                  if ( !defined($hotfixHash{$key}{date}) || $hotfixHash{$key}{date} eq "" ) {
                     $hotfixHash{$key}{date} = "0000-00-00";
                  }

                  # if the date is less than new date, take the new information since it's more current
                  if ( !defined($hotfixHash{$key}{date}) || $hotfixHash{$key}{date} le $logDate ) {
                     $logDate =~ s%-([1-9])-%-0$1-%; # zero-pad the month
                     $logDate =~ s%-([1-9])$%-0$1%; # zero-pad the day
                     $hotfixHash{$key}{date} = $logDate;
                     $hotfixHash{$key}{time} = $logTime;
                     $hotfixHash{$key}{status} = "Installed";
                  } else {
                     if ( !defined($hotfixHash{$key}{time}) || $hotfixHash{$key}{time} eq "" ) {
                        $hotfixHash{$key}{time} = "00:00:00";
                     }
                     if ( !defined($hotfixHash{$key}{status}) || $hotfixHash{$key}{status} eq "" ) {
                        $hotfixHash{$key}{status} = "UNKNOWN";
                     }
                  }
               }
            }
         } else {
            reporttext("\tINFO: file $pathstr was not found\n");
         }
      }

   }

   reporttext("\n");

   reporttext("\tHotfixes recorded in the System Registry and Windows Update log(s):\n\n");

   # use a custom sorting routine
   foreach my $key (sort
                    {
                       my ($a_isnum);
                       my ($b_isnum);
                       my ($a_kb);
                       my ($b_kb);
                       my ($a_ver);
                       my ($b_ver);

                       if ($a =~ m/^([0-9]+)((v[1-9][0-9]*)?)$/i) {
                          $a_kb = $1;
                          $a_ver = $2;
                          if (!defined($a_ver) || $a_ver eq "") {
                             $a_ver = 0;
                          } else {
                             $a_ver =~ s/^v//i;
                          }
                          $a_isnum = 1;
                       } else {
                          $a_isnum = 0;
                       }

                       if ($b =~ m/^([0-9]+)((v[1-9][0-9]*)?)$/i) {
                          $b_kb = $1;
                          $b_ver = $2;
                          if (!defined($b_ver) || $b_ver eq "") {
                             $b_ver = 0;
                          } else {
                             $b_ver =~ s/^v//i;
                          }
                          $b_isnum = 1;
                       } else {
                          $b_isnum = 0;
                       }

                       # if one is a number nad the other not, put the number first
                       if ($a_isnum != $b_isnum) {
                          if ($a_isnum) {
                             return -1;
                          } else {
                             return +1;
                          }
                       }

                       if ($a_isnum) {
                          # if they are both numbers, sort numerically by KB number, then by version
                          my ($kb_comp);

                          $kb_comp = $a_kb <=> $b_kb;
                          if ($kb_comp != 0) {
                             return $kb_comp;
                          }
                          return $a_ver <=> $b_ver;
                       } else {
                          # if they are both non-numbers, sort alphabetically
                          return $a cmp $b;
                       }
                    }
                    keys %hotfixHash) {
      reportdebug("key -> $key");
      reporttext("\tID: $hotfixHash{$key}{key} | INSTALL DATE: $hotfixHash{$key}{date} $hotfixHash{$key}{time} | STATUS: $hotfixHash{$key}{status} | DESCRIPTION: $hotfixHash{$key}{description}\n");
   }

   #############
   # ISSI Update
   #############

   reporttext("\n\tContents of ISSI Update file(s):\n\n");

   foreach my $key (@issi_update_files) {
      my ($pathstr);
      if ($localonly) {
         $pathstr = "$SystemRootTemp$key";
      } else {
         $pathstr = "\\\\$server\\$SystemRootTemp$key";
      }
      my ($line, $contents);

      if ( -f $pathstr ) {
        reporttext("\tINFO: file $pathstr was found\n");
        # open file
         if ( open(CFG,"<$pathstr") ) {
            # slurp the file in
            while ($line = <CFG>) {
               chomp $line;
               foreach my $keyword ( @issi_history_keywords ) {
                  if ( $line =~ m/$keyword/ ) {
                     reporttext("\t$line\n");
                     reportdebug("contents-> $line  keyword -> $keyword");
                  }
               }
            }
         } else {
            print ("Failed to read file $pathstr: $!\n");
            close(CFG);
            return();
         }
      } else {
         reporttext("\tINFO: file $pathstr was not found\n");
      }

      # close config file
      close(CFG);
   }

   if ( %required ) {
      my (%requiredfixHash);
      my @commonItems = ();

      reporttext("\n\tSAPM (APAR) Compliance:\n");
      foreach my $knumber ( sort keys %required ) {
         $knumber = ucfirst($knumber);
         my ($key) = $knumber;
         $key =~ s/^([0-9]{5,}(v[1-9][0-9]*)?)_.*$/$1/;
         $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?)(-|_).*$/$2/i;
         $key =~ s/^(KB|Wm|Q|M|S)([0-9]{3,}(v[1-9][0-9]*)?).*/$2/i;

         $requiredfixHash{$knumber}{key} = $knumber;
         $requiredfixHash{$knumber}{os} = $required{$knumber};
         reportdebug("requiredfixHash{key}{key} -> $requiredfixHash{$knumber}{key}");
         reportdebug("requiredfixHash{key}{os}  -> $requiredfixHash{$knumber}{os}");
         push(@commonItems, $knumber) if exists $hotfixHash{$key};

         if ((grep(/$osversion/, $requiredfixHash{$knumber}{os}))) {
            reportdebug("osversion -> $osversion");
            reportdebug("commonItems -> @commonItems");
            if ( defined($hotfixHash{$key}{key}) && (grep(/$hotfixHash{$key}{key}/, @commonItems)) ) {
               reporttext("\tPASS: Patch $requiredfixHash{$knumber}{key} is listed as required and is installed\n");
            } else {
               reportfail($server, "Patch $requiredfixHash{$knumber}{key} is listed as required but not installed\n");
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: check local and global administrator lists (global for PDC only)
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub privileged_groups_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@UserList,%Userlist);

   if ($servertype =~ /Primary/ || $servertype =~ /Backup/) {
      if (!Win32::NetAdmin::GroupGetMembers( "\\\\$server", "Domain Admins", \@UserList)) {
         reportsyserror($server, Win32::NetAdmin::GetError(), "cannot get Domain Admin user list");
      } else {
         my $tmp = $#UserList + 1;
         reporttext("\tThere are $tmp Domain Administrators\n");
         if ($verbose) {
            for(@UserList) {
               reporttext("\t\t$_\n");
            }
         }
      }
   }

   foreach my $localgroup (@privileged_groups) {
      if (Win32::NetAdmin::LocalGroupGetMembersWithDomain("\\\\$server", "$localgroup", \%Userlist)) {
         my $tmpg = scalar(keys %Userlist);
         reporttext("\tThere are $tmpg $localgroup\n");

         if ($verbose) {
            foreach my $key (keys %Userlist) {
               reporttext("\t\t$key\n");
               if ($Userlist{$key} == 2) {
                  reportdebug("pdcname -> $pdcname");
                  if ($pdcname) {
                     $key =~ s/(.*\\)//;
                     reportdebug("key -> $key");
                     if (!Win32::NetAdmin::GroupGetMembers( "\\\\$pdcname", "$key", \@UserList)) {
                        reportsyserror($server, Win32::NetAdmin::GetError(), "cannot get $key user list from $pdcname");
                     } else {
                        my $tmpm = $#UserList + 1;
                        reporttext("\t\tThere are $tmpm $key\n");
                        if ($verbose) {
                           for(@UserList) {
                              reporttext("\t\t\t$_\n");
                           }
                        }
                     }
                  } else {
                     reporterror($server, "cannot get $key user list unknown from unknown Domain Controller");
                  }
               }
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: check os file/directory DACL/SACL lists
#              (depends on server_version)
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub osr_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@resources, $sharename, $Root, $status);
   my (@excluded_resources);

   # set this to FILE or REGISTRY type in get_perms
   my ($type);

   if ($systemroot) {
      @resources = @all_resources;
      if ($localonly) {
         # don't convert the path
         $sharename = $systemroot;
      } else {
         # change the path to UNC convention
         $systemroot =~ s/:/\$/;
         $sharename = $systemroot;
      }
   } else {
      @resources = @sysroot_resources;
      reporterror($server, "OSR checks unable to obtain value of SystemRoot registry key, checking OSRs through ADMIN share");
      $sharename = "ADMIN\$";
   }

   my ($SystemRootTemp);
   my (%Volume);

   $SystemRootTemp = $systemroot;
   $SystemRootTemp = substr($SystemRootTemp, 0, 2);

   if ($localonly) {
      %Volume = Win32::AdminMisc::GetVolumeInfo("$SystemRootTemp");
   } else {
      %Volume = Win32::AdminMisc::GetVolumeInfo("\\\\$server\\$SystemRootTemp");
   }

   if (!%Volume) {
      reportsyserror($server, Win32::AdminMisc::GetError(), "cannot check OSR permissions: unable to get filesystem info for $SystemRootTemp");
      return();
   }

   if ($Volume{FileSystemName} eq "NTFS") {
      my ($regRelativePath, $regType, $requiredOS);

      foreach my $info (@resources) {
         ($regRelativePath, $regType, $requiredOS) = split(/:/, $info);
         if ($requiredOS =~ $osversion) {
            if ($localonly) {
               reporttext("\n\t$sharename$regRelativePath\n");
            } else {
               reporttext("\n\t\\\\$server\\$sharename$regRelativePath\n");
            }
            $status = get_perms("FILE", $sharename, $regRelativePath, $server);
            if ($status && ($status eq 'error')) {
               reporterror($server, "could not get audit perms for: $sharename$regRelativePath"); # FIXME: move error message into get_perms()
            }
         }
      }

      foreach my $info (@registry_value_perms) {
         my ($regRelativePath, $regRoot, $requiredOS) = split(/:/, $info);
         if ($requiredOS =~ $osversion) {
            if ($localonly) {
               reporttext("\n\t$regRelativePath\n");
            } else {
               reporttext("\n\t\\\\$server\\$regRelativePath\n");
            }

            if ( $regRoot eq "HKCR" ) {
               if (! $HKEY_CLASSES_ROOT->Connect($server, $Root)) {
                  reportsyserror($server, Win32->GetLastError(), "unable to connect to registry"); # %%%%FIXME
               }
            }

            if ( $regRoot eq "HKLM" ) {
               if (! $HKEY_LOCAL_MACHINE->Connect($server, $Root)) {
                  reportsyserror($server, Win32->GetLastError(), "unable to connect to registry"); # %%%%FIXME
               }
            }

            if ( $regRoot eq "HKCU" ) {
               if (! $HKEY_CURRENT_USER->Connect($server, $Root)) {
                  reportsyserror($server, Win32->GetLastError(), "unable to connect to registry"); # %%%%FIXME
               }
            }

            if ( $regRoot eq "HKUS" ) {
               if (! $HKEY_USERS->Connect($server, $Root)) {
                  reportsyserror($server, Win32->GetLastError(), "unable to connect to registry"); # %%%%FIXME
               }
            }

            if ( $regRoot eq "HKCC" ) {
               if (! $HKEY_CURRENT_CONFIG->Connect($server, $Root)) {
                  reportsyserror($server, Win32->GetLastError(), "unable to connect to registry"); # %%%%FIXME
               }
            }

            # if Terminal Services HKEY_CLASSES_ROOT check

            if ($regRelativePath eq "HKEY_CLASSES_ROOT" ) {
               # name of the service as it appears in the Registry
               my (%status);
               my $service = "TermService";
               my $serviceName = "Terminal Services";
               my $serviceNameConfig = "terminal_server_osr_registry_resource_check";
               my $serviceResult = is_service_enabled($server, $osversion, $osservicepack, $osarch, $service);

               if ($terminal_server_osr_registry_resource_check eq "no" && $serviceResult == 1) {
                  reportwarn($server, "$serviceName appears be be enabled, but $serviceNameConfig is set to no in $config_file!\n");
                  $status = get_perms("REGISTRY", $sharename, $regRelativePath, $server);
               }

               if ($terminal_server_osr_registry_resource_check eq "yes" && $serviceResult == 1) {
                  $status = get_perms("REGISTRY", $sharename, $regRelativePath, $server);
               } else {
                  if ($terminal_server_osr_registry_resource_check eq "yes" && $serviceResult == 0) {
                     if (!Win32::Service::GetStatus("\\\\$server", $service, \%status)) {
                        reporttext("\t$serviceName does not appear to be installed on $server; skipping checks!");
                     } else {
                        reporttext("\t$serviceName is set for manual startup but is currently running; not skipping checks!\n") if ($status{CurrentState} == 4);
                        $status = get_perms("REGISTRY", $sharename, $regRelativePath, $server);
                     }
                  } else {
                     if ($serviceResult == -1) {
                        reporttext("\t$serviceName could not be found in the Service area of the Registry!\n");
                     }
                  }
               }
            }

            # perform other Registry check(s)

            if ($regRelativePath ne "HKEY_CLASSES_ROOT") {
               $status = get_perms("REGISTRY", $sharename, $regRelativePath, $server);
            }

            if ($status && ($status eq 'error')) {
               reporterror($server, "could not get perms for: $Root"); # FIXME: move error message into get_perms()
            }

         }
      }
   } else {
      # FAT1[26], FAT3[12], other
      reportfail($server, "cannot check OSR permissions: $SystemRootTemp is formatted with the $Volume{FileSystemName} format");
   }

   return();
}

####################################################################
#
# Description: routine which does the actual permissions checking
#
# Accepts: type (FILE or REGISTRY)
#          share (where the FILE or REGISTRY resides)
#          relpath (the relative path)
#          server
#
# Returns: nothing
#
####################################################################

sub get_perms ($$$$) {
   my ($type, $share, $relpath, $server) = @_;
   my ($Perm, @array);
   my ($owner, $audit, $everyone, $users, $authusers, $count);

   # Must use path for file checks, otherwise the path is not found
   if ( $type eq "FILE" ) {
      my ($netpath);
      if ($localonly) {
         $netpath = "$share$relpath";
      } else {
         $netpath = "\\\\$server\\$share$relpath";
      }
      $Perm = new Win32::Perms($netpath) || return('error');
   }

   # Must use relative_path for registry checks, otherwise just the root perms are returned
   if ( $type eq "REGISTRY" ) {
      my ($netpath);
      if ($localonly) {
         $netpath = "$relpath";
      } else {
         $netpath = "\\\\$server\\$relpath";
      }
      $Perm = new Win32::Perms($netpath) || return('error');
   }

   $Perm->Dump(\@array);

   foreach my $element (@array) {

      my (@Perms, @FPerms, @Flag, @Type, $account_name, $account);
      my (@errArray) = ();

      # These are available values for $element:
      #
      # ${$element}{'Account'}
      # ${$element}{'Domain'}
      # ${$element}{'Mask'}
      # ${$element}{'Perms'}
      # ${$element}{'Type'}
      # ${$element}{'Flag'}

      Win32::Perms::DecodeMask($element,\@Perms,\@FPerms);
      Win32::Perms::DecodeType($element,\@Type);
      Win32::Perms::DecodeFlag($element,\@Flag);

      next if $element->{Entry} eq "Group";
      $account_name = $element->{Account};
      next unless $account_name;

      $account = "$account_name";
      $account = "$element->{Domain}\\$account" if $element->{Domain};

      if ($element->{Entry} eq "Owner") {
         $owner = $account;
         next;
      }

      if ($element->{Entry} eq "SACL") {
         $audit = 1;
         reporttext("\tFile Auditing for $account is set to $Flag[0] - $Flag[1]\n") if $verbose;
         next;
      }

      reporttext("\n\t$account\n\t@Perms\n") if $verbose;

      $everyone_perms{$relpath} =~ s/\s+/:/gm;
      $everyone_perms{$relpath} =~ s/:/ /gm;

      foreach my $key (@Perms) {
         if ( $account_name eq "Everyone" || $account_name eq "Users" || $account_name eq "Authenticated Users" ) {
            if ( $everyone_perms{$relpath} !~ /$key/) {
               push(@errArray, $key);
               if ( $account_name eq "Everyone" ) {
                  $everyone++;
               }
               if ( $account_name eq "Users" ) {
                  $users++;
               }
               if ( $account_name eq "Authenticated Users" ) {
                  $authusers++;
               }
               $count++;
            }
         }
      }

      if ( $count ) {
         if ( $everyone && $account_name eq "Everyone" ) {
            reportfail($server, "Improper permissions on $relpath for Everyone (@errArray). Permissions should be maximum of ($everyone_perms{$relpath})");
         }
         if ( $users  && $account_name eq "Users" ) {
            reportfail($server, "Improper permissions on $relpath for Users (@errArray). Permissions should be maximum of ($everyone_perms{$relpath})");
         }
         if ( $authusers  && $account_name eq "Authenticated Users" ) {
            reportfail($server, "Improper permissions on $relpath for Authenticated Users (@errArray). Permissions should be maximum of ($everyone_perms{$relpath})");
         }
         $count = 0;
      }

      if ( $debug ) {
         foreach my $key (sort keys (%{$element})) {
            reporttext("\t\t$key = ${$element}{$key}\n");
         }
         reporttext("\t\tPerms = ");
         foreach my $key (@Perms) {
            reporttext("$key ");
         }
         reporttext("\n");
      }

   }

   # If set then perform audit check, but do not report auditing on REGISTRY keys
   if ( $extended_osr_resource_check eq "yes" && $type ne "REGISTRY" ) {
      reportfail($server, "Auditing is not set for $relpath") unless $audit;
   }

   reporttext("\n\tOwner is $owner\n") if ($owner && $verbose);

   if ($audit && !$everyone) {
      # Don't report auditing on REGISTRY keys
      if ( $extended_osr_resource_check eq "yes"  && $type ne "REGISTRY" ) {
         reporttext("\tAuditing & permissions correct on $relpath\n");
      } else {
         reporttext("\tPermissions correct on $relpath\n");
      }
   } else {
      reporttext("\tPermissions correct\n") unless $everyone || $users;
      reporttext("\tAuditing is set\n") if $audit;
   }

   $Perm->Close();

   return();
}


sub schstr
{
my($str,$i)=@_;
if ($str=~/$i/i) {return 1;}
else {return 0;}
}

sub Getbit
{
my(@bit)=grep /System type/i,@b=`systeminfo`;
if(schstr($bit[0],"64")){$osbit="64bit";}
else {$osbit="32bit";}
return ($osbit);
}

####################################################################
#
# Description: Symantec AntiVirus Checks
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: 0 if service is disabled
#          1 if service is enabled
#
####################################################################

sub av_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($avversion);
   my ($valueString);
   my ($remKey);
   my ($major, $middle, $minor, $minorx);
   my (%FileInfo);
   my ($drive, $rest);
   my ($rtvscan);
   my (@subkeynames);
   my ($subkeyservice);
   my (%status);
   my ($value_str);
   my ($AVType);
   my ($st);
   my ($location);

   # get the current date
   my ($Sec,$Min,$Hour,$Day,$Month,$Year) = get_date();

   # Attempt to determine SAV Version by checking revision of file rtvscan.exe

   if ($localonly) {
      $UncPath = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\";
   } else {
      $UncPath = "\\\\$server\\HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\";
   }
   $remKey = $Registry->{$UncPath};
   if (!$remKey) {
      reportsyserror($server, Win32->GetLastError(), "unable to retrieve services registry information"); # %%%%FIXME
   } else {
      (@subkeynames) = $remKey->SubKeyNames;
      foreach my $subkeyservice (@subkeynames) {
         # Search for Symantec AntiVirus and Symantec AntiVirus, because Norton Program Scheduler also exists as a service
         if ($subkeyservice =~ /Norton AntiVirus/ || $subkeyservice =~ /Symantec AntiVirus/) {
            my ($avSvcKey, $avSvcPath, $avSvcStart);
            my ($avRtKey, $avRtFlag);

            if ($localonly) {
               $UncPath = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\$subkeyservice";
            } else {
               $UncPath = "\\\\$server\\HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\$subkeyservice";
            }
            $avSvcKey = $Registry->{$UncPath};

            $avSvcPath = $avSvcKey->GetValue("ImagePath");
            # clean out double quotes if they exist
            $avSvcPath =~ s/"//g;
            if ($localonly) {
               $rtvscan = $avSvcPath;
            } else {
               ($drive, $rest) = split(/:/, $avSvcPath);
               $rest =~ s/\\/\//g;
               $rtvscan = "//".$drive."\$".$rest;
               $rtvscan = "//".$server."/".$drive."\$".$rest;
            }

            # FIXME: use $verbose in this routine?
            $avSvcStart = $avSvcKey->GetValue("Start");
            if (hex($avSvcStart)==0) {
               reportwarn($server, "$subkeyservice is NOT set to run on startup\n")
            } else {
               reporttext("\t$subkeyservice is set to run on startup\n")
            }

if ((Getbit) == 64)
{
            if ($localonly) {
               $UncPath = "$sep_rtscan_settings";
            } else {
               $UncPath = "\\\\$server\\$sep_rtscan_settings";
            }
}else{
                      if ($localonly) {
               $UncPath = "$sep_rtscan_settings_32";
            } else {
               $UncPath = "\\\\$server\\$sep_rtscan_settings_32";
            }
       }  
            #print $UncPath;
            $avRtKey = $Registry->{$UncPath};

            $avRtFlag = $avRtKey->GetValue("OnOff");
            if (hex($avRtFlag)==0) {
               my ($seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst) = localtime(hex($avRtKey->GetValue("APEOff")));
               my ($avRtTime) = sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);
               my ($avRtDate) = sprintf("%02d/%02d/%04d", $month, $day_of_month, 1900 + $year);

               reportfail($server, "RealTimeScan filesystem protection was disabled at $avRtTime on $avRtDate\n")
            } else {
               reporttext("\tRealTimeScan filesystem protection is Enabled\n")
            }

            if (!Win32::AdminMisc::GetFileInfo($rtvscan, \%FileInfo)) {
               reportsyserror($server, Win32::AdminMisc::GetError(), "unable to get RealTimeVirusScan file information for $rtvscan");
               $avversion = 0;
            } else {
               my $rtvscanversion = $FileInfo{"FileVersion"};
               reporttext("\tSymantec AntiVirus RealTimeVirusScan file is at version level: $rtvscanversion\n");
               # Set version number from rvtscan.exe file information
               $avversion = $rtvscanversion;
            }

            if (!Win32::Service::GetStatus("\\\\$server", "$subkeyservice", \%status)) {
               reportsyserror($server, Win32->GetLastError(), "unable to retrieve service status for $subkeyservice on $server"); # %%%%FIXME
            } else {
               reporttext("\t$subkeyservice is currently running\n") if ($status{CurrentState} == 4);
               reportwarn($server, "$subkeyservice is not currently running") if ($status{CurrentState} == 1);
            }
         }
      }
   }
   undef $remKey;

   # Check to see if client is SAV standalone or Symantec System Center type
if ((Getbit) == 64)
{
   if ($localonly) {
      $UncPath = "$sep_current_version"
   } else {
      $UncPath = "\\\\$server\\$sep_current_version";
   }
 }else{
    if ($localonly) {
      $UncPath = "$sep_current_version_32"
   } else {
      $UncPath = "\\\\$server\\$sep_current_version_32";
   }
   }
   if (!($remKey = $Registry->{$UncPath})) {
         reportsyserror($server, Win32->GetLastError(), "cannot connect to SAV current version location in registry");
         return();
   } else {
      my ($avParent);
      $avParent = $remKey->GetValue("Parent");
      reportdebug("avParent: $avParent");
      if ( $avParent eq "" ) {
         $AVType = "SAV";
      } else {
         $AVType = "SSC";
      }
   }

   # Check SAV Registry settings to determine compliance

if ((Getbit) == 64)
{
   foreach my $setting (@sep_registry_settings) {
      my ($regKeyLocation, $regValueName, $regValueType, $regRequiredValue, $regAVType, $regRangeCheck, $regErrorLevel, $regDescription, $regRequiredOS) = split(/:/, $setting);
      reportdebug("$regKeyLocation, $regValueName, $regValueType, $regRequiredValue, $regAVType, $regRangeCheck, $regErrorLevel, $regDescription, $regRequiredOS");
      my $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);

      if ( $regAVType eq $AVType ) {

         if ($value eq "1") {
            $value_str = "Enabled";
         } elsif ($value eq "0") {
            $value_str = "Disabled";
         } else {
            if (!defined($value)) {
            $value_str = "Undefined";
            } else {
               $value_str = $value;
            }
         }

         reportdebug("$value $regRangeCheck $regRequiredValue $regErrorLevel");

           if ( (($value ne $regRequiredValue) && $regRangeCheck eq "=") || (($value > $regRequiredValue) && $regRangeCheck eq "<") || (($value < $regRequiredValue) && $regRangeCheck eq ">") ) {
            if ($regErrorLevel eq "FAIL") {
               reportfail($server, "Registry setting for [$regDescription] is $value_str. Should be $regRequiredValue\n");
            } else {
               if ($regErrorLevel ne "SKIP" ) {
                  reportwarn($server, "Registry setting for [$regDescription] is $value_str. Should be $regRequiredValue\n");
               }
            }
         } elsif ($verbose) {
            reporttext("\tRegistry setting for [$regDescription] is $value_str\n");
         }

      }
   }
}else{
   foreach my $setting (@sep_registry_settings_32) {
      my ($regKeyLocation, $regValueName, $regValueType, $regRequiredValue, $regAVType, $regRangeCheck, $regErrorLevel, $regDescription, $regRequiredOS) = split(/:/, $setting);
      reportdebug("$regKeyLocation, $regValueName, $regValueType, $regRequiredValue, $regAVType, $regRangeCheck, $regErrorLevel, $regDescription, $regRequiredOS");
      my $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);

      if ( $regAVType eq $AVType ) {

         if ($value eq "1") {
            $value_str = "Enabled";
         } elsif ($value eq "0") {
            $value_str = "Disabled";
         } else {
            if (!defined($value)) {
            $value_str = "Undefined";
            } else {
               $value_str = $value;
            }
         }

         reportdebug("$value $regRangeCheck $regRequiredValue $regErrorLevel");

           if ( (($value ne $regRequiredValue) && $regRangeCheck eq "=") || (($value > $regRequiredValue) && $regRangeCheck eq "<") || (($value < $regRequiredValue) && $regRangeCheck eq ">") ) {
            if ($regErrorLevel eq "FAIL") {
               reportfail($server, "Registry setting for [$regDescription] is $value_str. Should be $regRequiredValue\n");
            } else {
               if ($regErrorLevel ne "SKIP" ) {
                  reportwarn($server, "Registry setting for [$regDescription] is $value_str. Should be $regRequiredValue\n");
               }
            }
         } elsif ($verbose) {
            reporttext("\tRegistry setting for [$regDescription] is $value_str\n");
         }

      }
   }
   }
   # Check SAV Virus Definitions Date

   if ($localonly) {
      $UncPath = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Symantec\\SharedDefs\\DefWatch";
   } else {
      $UncPath = "\\\\$server\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Symantec\\SharedDefs\\DefWatch"
   }

   if (!($remKey = $Registry->{$UncPath})) {
      reportsyserror($server, Win32->GetLastError(), "cannot connect to SAV virus definition update location"); # %%%%FIXME
      undef $remKey;
   } else {
      #if ( $avversion == 5 ) {
         $valueString = $remKey->GetValue("SystemTime");
      #} else {
      if (!$valueString) {
         $valueString = $remKey->GetValue("DefVersion");
      }
   }

   # Report SAV Findings

   # take $avversion and convert it to format of x.xx for comparison with $av_min_version
   ($major,$middle,$minor,$minorx) = split(/\./, $avversion);
   $avversion = "$major.$middle$minor";

   if ($verbose) {
      reporttext("\tSymantec AntiVirus on $osarch architecture is at version level: $avversion\n");
   }

   # Check Architecture to determine minimum version required

   # The format of the @av_min_version array is: "RequiredMinimumVersion:Architecture:ErrorLevel:RequiredOnOperatingSystem",
   #
   # Architecture maps to:
   #
   # x86
   # AMD64
   # IA64

   foreach $location (@av_min_version) {
      my ($regMinVersion, $regArchitecture, $regErrorLevel, $requiredOS) = split(/:/, $location);
         if ($requiredOS =~ $osversion && $regArchitecture =~ $osarch) {
               if ($regErrorLevel eq "FAIL") {
                  if ( $avversion < $regMinVersion ) {
                     reportfail($server, "Symantec AntiVirus $avversion is out of date, version $regMinVersion is required\n");
                  }
               } else {
                  if ( $avversion < $regMinVersion ) {
                     reportwarn($server, "Symantec AntiVirus $avversion is out of date, version $regMinVersion is required\n");
                  }
               }
         }
   }

   if (!$valueString) {
      reportfail($server, "Symantec AntiVirus $avversion definitions date could not be determined\n");
   } else {
      my ($av_year, $av_month, $av_dayofweek, $av_day) = unpack("vvvv", $valueString);
      my ($av_age) = Delta_Days($av_year, $av_month, $av_day, $Year, $Month, $Day);

      if ($av_age <= $av_max_age) {
         reporttext("\tSymantec AntiVirus $avversion definitions date is $av_month/$av_day/$av_year ($av_age days ago)\n");
      } else {
         my ($av_date) = sprintf("%02d/%02d/%04d", $av_month, $av_day, $av_year);

         # The format of the %av_final_date is: "M/D/YYYY",
         if (defined $av_final_update{$osversion}) {
            my ($av_fin_month, $av_fin_day, $av_fin_year) = split(/\//, $av_final_update{$osversion});
            my ($av_res) = "PASS";
            my ($av_fin_date) = sprintf("%02d/%02d/%04d", $av_fin_month, $av_fin_day, $av_fin_year);

            if ($av_year < $av_fin_year) {
               $av_res = "FAIL";
            } elsif ($av_year == $av_fin_year) {
               if ($av_month < $av_fin_month) {
                  $av_res = "FAIL";
               } elsif ($av_month == $av_fin_month) {
                  if ($av_day < $av_fin_day) {
                     $av_res = "FAIL";
                  }
               }
            }

            if ($av_res eq "FAIL") {
               reportfail($server, "Symantec AntiVirus $avversion definitions date is $av_date ($av_age days ago); no definition updates for $osversion were produced after $av_fin_date");
            } else {
               reporttext("\tSymantec AntiVirus $avversion definitions date is $av_date ($av_age days ago); no definition updates for $osversion were produced after $av_fin_date\n");
            }
         } else {
             reportfail($server, "Symantec AntiVirus $avversion definitions date is $av_date ($av_age days ago)");
         }
      }
   }

   # SAV Routine ends here

   return();
}

####################################################################
#
# Description: Symantec AntiVirus History Log Checks
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub av_history ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($avversion);
   my ($valueString);
   my ($remKey);
   my ($major, $middle, $minor, $minorx);

   my (%FileInfo);
   my ($drive, $rest);
   my ($rtvscan);
   my (%status);
   my ($value_str);
   my ($SystemRootTemp);

   # get the current date
   my ($Sec,$Min,$Hour,$Day,$Month,$Year) = get_date();

   my $DeltaDays = $av_history_delta_days;
   my ($Dyear,$Dmonth,$Dday) = Add_Delta_Days($Year,$Month,$Day,$DeltaDays);
   my $j = Delta_Days($Year,$Month,$Day,$Dyear,$Dmonth,$Dday);

   for ( my $i = 0; $i >= -$j; $i-- ) {
      my ($Nyear,$Nmonth,$Nday) = Add_Delta_Days($Year,$Month,$Day,$i);
      my $ndate = sprintf("%02d%02d%04d",$Nmonth,$Nday,$Nyear);
      push (@ndates, $ndate);
   }

   if ($localonly) {
      # don't convert path
      $SystemRootTemp = $systemroot;
      #print $SystemRootTemp;
      $SystemRootTemp = substr($SystemRootTemp, 0, 2);
   } else {
      # set systemroot and convert to UNC path
      $systemroot =~ s/:/\$/;
      $SystemRootTemp = $systemroot;
      $SystemRootTemp = substr($SystemRootTemp, 0, 2);
   }

   if ( $alt_av_history == 1 ) {
      @av_history_settings = @alt_av_history_settings;
      
   }

   foreach my $key ( @av_history_settings ) {
      my ($pathstr);
      if ($localonly) {
         $pathstr = "$SystemRootTemp$key";
      } else {
         $pathstr = "\\\\$server\\$SystemRootTemp$key";
      }
      if ( -d $pathstr ) {
         reportdebug("pathstr-> $pathstr");
         find (\&find_av_files, $pathstr);
      }
   }

   # Report results
   my @sorted = sort {$a cmp $b} @avmsgs;
   foreach my $item ( @sorted ) {
      reporttext("\t$item");
   }

   # Clear all global arrays related to SAV
   @ndates   = ();
   @nfiles   = ();
   @avmsgs  = ();
   $avmsgno = 0;

   return();
}

####################################################################
#
# Description: read in av history files, and place data in memory
#
# Accepts: filename (fullpath)
#
# Returns: nothing
#
####################################################################

sub find_av_files {
   my $item;
   my $filename = $File::Find::name;

   if ( -T $filename && grep(/.Log/,$filename) && grep(/Symantec/,$filename) ) {
      foreach $item ( @ndates ) {
         reportdebug("ndate-> $item");
         if ( grep(/$item/,$filename) ) {
            reportdebug("filename-> $filename");
            push (@nfiles, $filename);
            # open files and input data into memory
            &read_av_file($filename, $_);
         }
      }
   }
   return();
}

####################################################################
#
# Description: read in av history files, and place data in memory
#
# Accepts: filename (fullpath)
#
# Returns: nothing
#
####################################################################

sub read_av_file ($$) {
   my ($filename, $shortfilename) = @_;
   my ($ftemp, $ftempx) = split(/\./, $shortfilename);
   my ($line, $contents);

   # open file
   if ( open(CFG,"<$filename") ) {
      # slurp the file in
      while ($line = <CFG>) {
         chomp $line;
         foreach my $keyword ( @av_history_keywords ) {
            if ( $line =~ m/$keyword/ ) {
               $avmsgs[++$avmsgno] = "$ftemp".","."$line\n";
            }
         }
      }
   } else {
      reporttext("Failed to read file $filename: $!\n");
      close(CFG);
      return();
   }

   # close config file
   close(CFG);

   return();
}

####################################################################
#
# Description: screen saver settings for profiles
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub screensaver_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, @subkeynames, $failures);

   if ($localonly) {
      $UncPath = "HKEY_USERS\\";
   } else {
      $UncPath = "\\\\$server\\HKEY_USERS\\";
   }
   $remKey = $Registry->{$UncPath};

   if (!$remKey) {
      reportsyserror($server, Win32->GetLastError(), "cannot connect to HKEY_USERS registry setting"); # %%%%FIXME
      undef $remKey; # FIXME: redundant?
      return();
   }

   @subkeynames = $remKey->SubKeyNames;

   foreach my $subkeyprofile (@subkeynames) {
      my (@ss_sids, $ss_account, @info);

      $ss_account = "";
      if ($subkeyprofile !~ /DEFAULT/) {
         my $bin_sid = Win32::Lanman::StringToSid($subkeyprofile);
         push(@ss_sids,$bin_sid);

         if (Win32::Lanman::LsaLookupSids("$server", \@ss_sids, \@info)) {
            $ss_account = "${$info[0]}{domain}\\${$info[0]}{name}";
         }
      }

      my $profile_ss_verify = $remKey->{"$subkeyprofile\\"};
      if (!defined($profile_ss_verify)) {
         reportsyserror($server, Win32->GetLastError(), "unable to obtain screensaver settings for $subkeyprofile"); # %%%%FIXME
         next;
      }

      my @profile_subkeys = $profile_ss_verify->SubKeyNames;
      next unless (grep(/Control/, @profile_subkeys));
      my $screen_saver = $remKey->{"$subkeyprofile\\Control Panel\\Desktop\\"};
      my $ssto = $screen_saver->GetValue("ScreenSaveTimeOut");
      my $ssa = $screen_saver->GetValue("ScreenSaveActive");
      my $ssexe = $screen_saver->GetValue("SCRNSAVE.EXE");
      my $ssis = $screen_saver->GetValue("ScreenSaverIsSecure");

      $ss_account = $subkeyprofile if ($ss_account eq "");
      reporttext("\t$ss_account\t($subkeyprofile)\n") if $verbose;

      if ($ssto > $screen_saver_timeout) {
         reportwarn($server, "$ss_account Screen Saver Timeout = $ssto. Should be $screen_saver_timeout");
         $failures++;
      } elsif ($verbose) {
         reporttext("\t\tScreen Saver Timeout = $ssto\n");
      }

      if ($ssa != $screen_saver_active) {
         reportwarn($server, "$ss_account: Screen saver active = $ssa. Should be $screen_saver_active");
         $failures++;
      } elsif ($verbose) {
         reporttext("\t\tScreen saver is active\n") if ($ssa == 1);
         reporttext("\t\tScreen saver is NOT active\n") if ($ssa == 0);
      }

      my $found_exe = 0;
      for (my $index=0; $index<scalar(@screen_saver_exes); $index++) {
        if (lc($ssexe) eq $screen_saver_exes[$index] ||
            lc($ssexe) =~ /^.*\\$screen_saver_exes[$index]$/) {
          $found_exe = 1;
          last;
        }
      }
      if (!$found_exe) {
         reportwarn($server, "$ss_account: Screen saver executable = $ssexe. Possibly insecure suggest using $screen_saver_exes[0]");
         $failures++;
      } elsif ($verbose) {
         reporttext("\t\tScreen saver is $ssexe\n");
      }

      if ($ssis != $screen_saver_is_secure) {
         reportwarn($server, "$ss_account: Screen saver Security = $ssis. Should be $screen_saver_is_secure");
         $failures++;
      } elsif ($verbose) {
         reporttext("\t\tScreen saver is secure\n") if ($ssis == 1);
         reporttext("\t\tScreen saver is NOT secure\n") if ($ssis ==0);
      }

      if (!$failures) {
         reporttext("\t$ss_account: Screen saver settings are correct\n");
      }
   }

   undef $remKey;
   return();
}

####################################################################
#
# Description: check drive format
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub logical_drive_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my (@drives);

   if (!Win32::NetAdmin::GetServerDisks("\\\\$server",\@drives)) {
      reportsyserror($server, Win32::NetAdmin::GetError(), "unable to get list of drives");
      return();
   }

   foreach my $drive (@drives) {
      my (%Volume);
      reportdebug("$drive");
      $drive =~ s/:/\$/;
      if ($localonly) {
         $UncPath = "$drive";
      } else {
         $UncPath = "\\\\$server\\$drive";
      }

      reportdebug("UNCPATH: $UncPath");

      if ( %Volume = Win32::AdminMisc::GetVolumeInfo($UncPath) ) {
         if ($Volume{FileSystemName} eq "NTFS") {
            reporttext("\t$drive is formatted with the $Volume{FileSystemName} filesystem\n");
         } else {
            reportfail($server, "$drive is formatted with the $Volume{FileSystemName} filesystem");
         }
      } else {
         #reportsyserror($server, Win32::AdminMisc::GetError(), "unable to retrieve volume information for $drive on $server");
      }
   }

   return();
}

####################################################################
#
# Description: check account password expiration policy
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub password_expiry_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($count);

   if ($servertype =~ /Backup/) {
      return() unless ($getglobalusers == 1);
   } elsif ($servertype =~ /Primary/ || $servertype eq "") {
      return() unless ($getglobalusers == 1);
   }

   my ($IUSR) = "iusr_"."$server";
   my ($IWAM) = "iwam_"."$server";
   my ($VUSR) = "vusr_"."$server";
   my (@excludeUsers) = ("$IUSR",
                         "$IWAM",
                         "$VUSR",
                         "TsInternetUser",
                         "Replicate",
                         "Guest"
                         );

   # un-comment for debugging purposes only
   # my (@excludeUsers) = ();

   my (@notexcludeGroups) = ("Administrators",
                             "Domain Admins",
                             "Enterprise Admins",
                             );

   my (@notexcludeRight) = ("SeInteractiveLogonRight");
   my ($Group, @Groups, @localGroups);
   my ($User, @List);
   my ($message);
   my ($intInteractiveLogonRight, $intNetworkLogonRight);

   my @egroups = &enumerate_accounts_with_rights($server, &SE_INTERACTIVE_LOGON_NAME);

   # only retrieve normal accounts, because otherwise a timeout will occur for MACHINE accounts
   if (!Win32::NetAdmin::GetUsers("\\\\$server", FILTER_NORMAL_ACCOUNT, \@List)) {
      reportsyserror($server, Win32::NetAdmin::GetError(), "unable to gather user listing from server");
      return();
   }
      foreach $User ( @List ) {
      #if ( grep {/$User/i} @excludeUsers || $User =~ m/\$/ ) {
      if ( grep {/$User/i} @excludeUsers ) {
            next;
         } else {
            my (@sameGroups, @adminGroups, @localGroups) = ();
            my $expires = &password_never_expires($server, $User);
            my $disabled = &account_is_disabled($server, $User);
            my @erights = &enumerate_user_rights($server, $User);

            if (!Win32::Lanman::NetUserGetLocalGroups("\\\\$server", $User, '', \@Groups)) {
               reportsyserror($server, Win32::Lanman::GetLastError(), "unable to retrieve groups for user $User");
               return();
            }

            foreach $Group ( @Groups ) {
               push(@localGroups, ${$Group}{'name'});
            }

            foreach my $item ( @localGroups ) {
               for ( my $i = 0; $i < @egroups; $i++ ) {
                  if ( $item eq $egroups[$i] ) {
                     push(@sameGroups, $item);
                  }
               }

            for ( my $i = 0; $i < @notexcludeGroups; $i++ ) {
               if ( $item eq $notexcludeGroups[$i] ) {
                  push(@adminGroups, $notexcludeGroups[$i]);
               }
            }
         }

         # 'password never expires' is 1, 'account is disabled' is 1

         if ( $expires == 1 && $disabled == 0 ) {

            $intInteractiveLogonRight = grep {/SeInteractiveLogonRight/i} @erights;
            $intNetworkLogonRight = grep {/SeNetworkLogonRight/i} @erights;

            if ( ($intInteractiveLogonRight > 0) || ($intNetworkLogonRight > 0) || ($#sameGroups > -1) || ($#adminGroups > -1) ) {

               if ( $expires == 1) {
                  $message = "$User account: 'password never expires' is set";
               }

               if ( grep {/SeInteractiveLogonRight/i} @erights ) {
                  $message = $message . ", ";
                  $message = $message . "'logon locally' is set";
               }

               if ( grep {/SeNetworkLogonRight/i} @erights ) {
                  $message = $message . ", ";
                  $message = $message . "'access this computer from the network' is set";
               }

               if ( $#sameGroups > -1 ) {
                  $message = $message . ", ";
                  $message = $message . "belongs to 'interactive login' rights group(s): @sameGroups";
               }

               if ( $#adminGroups > -1 ) {
                  $message = $message . ", ";
                  $message = $message . "belongs to administrative group(s): @adminGroups";
               }

               reportfail($server, "$message\n");
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: enumerate the rights for a specific account
#
# Accepts: server
#          username
#
# Returns: array of account privledges
#          "error" if there was an error (because the caller expects an array)
#
####################################################################

sub enumerate_user_rights ($$) {
   my ($server, $username) = @_;

   my (@sids, @infos, @privileges);
   my ($priv);

   if (!Win32::Lanman::LsaLookupNames("\\\\$server", [$username], \@infos)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "cannot perform LSA information lookup on username $username");
      return("error");
   }

   if (!Win32::Lanman::LsaEnumerateAccountRights("\\\\$server", ${$infos[0]}{sid}, \@privileges)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "cannot enumerate account rights on username $username");
      return("error");
   }

   reportdebug("user -> $username");
   foreach $priv (@privileges) {
      reportdebug("priv -> $priv");
   }

   return(@privileges);
}

####################################################################
#
# Description: enumerate accounts with specific rights
#
# Accepts: server
#          rights
#
# Returns: array of accounts
#          nothing (if there was an error)
#
####################################################################

sub enumerate_accounts_with_rights ($$) {
   my ($server, $rights) = @_;

   my (@sids, @infos, @privileges);
   my (@list);

   if (!Win32::Lanman::LsaEnumerateAccountsWithUserRight("\\\\$server", $rights, \@sids)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "uname to enumerate accounts with local logon rights");
      return();
   }

   if (!Win32::Lanman::LsaLookupSids("\\\\$server", \@sids, \@infos)) {
      reportsyserror($server, Win32::Lanman::GetLastError(), "sid lookup failed");
      return();
   }

   foreach my $info (@infos) {
      push(@list, "${$info}{name}");
      reportdebug("${$info}{name}");
   }

   return(@list);
}

####################################################################
#
# Description: check business use notice
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub biz_use_notice_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($caption_count, $notice_count, $logon_count) = (0, 0, 0);
   my ($count);
   my (@business_use_notice);
   my ($caption, $notice, $logon) = ("", "", "");
   my ($caption_final, $notice_final, $logon_final);

   # The format is:  "Location:ErrorLevel:RequiredOnOperatingSystem"
   # "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\:FAIL:5.0 5.1 5.2",
   my ($regKeyLocation, $regErrorLevel, $requiredOS);

   foreach $location (@business_use_notice_registry_keys) {
      ($regKeyLocation, $regErrorLevel, $requiredOS) = split(/:/, $location);

      reportdebug("looking in: $location");

      if ($requiredOS =~ $osversion) {
         if ($caption_count == 0 || $notice_count == 0 || $logon_count == 0) {
            if ($localonly) {
               $UncPath = "$regKeyLocation";
            } else {
               $UncPath = "\\\\$server\\$regKeyLocation";
            }
            $remKey = $Registry->{$UncPath};

            if (!$remKey) {
               next;
            } else {
               $caption = $remKey->GetValue("LegalNoticeCaption");
               $notice = $remKey->GetValue("LegalNoticeText");
               $logon = $remKey->GetValue("LogonPrompt");

               if ($business_use_notice_check eq "1") {
                  @business_use_notice = @business_use_notice_usa;
               } else {
                  @business_use_notice = @business_use_notice_other;
               }

               foreach my $item (@business_use_notice) {
                  reportdebug("searching for: $item");
                  #if ( $item =~ m/$caption/i ) {
                  if (grep {/$item/i} $caption) {
                     $caption_count++;
                     $count++;
                     reportdebug("caption_count: $caption_count");
                     reportdebug("found: $caption");
                     $caption_final = $caption;
                     next;
                  }
                  #if ( $item =~ m/$notice/i ) {
                  if (grep {/$item/i} $notice) {
                     $notice_count++;
                     $count++;
                     reportdebug("notice_count: $notice_count");
                     reportdebug("found: $notice");
                     $notice_final = $notice;
                     next;
                  }
                  #if ( $item =~ m/$logon/i ) {
                  if (grep {/$item/i} $logon) {
                     $logon_count++;
                     $count++;
                     reportdebug("logon_count: $logon_count");
                     reportdebug("found: $logon");
                     $logon_final = $logon;
                     next;
                  }
               }
            }
         }
      }
   }

   if ( ($business_use_notice_check eq "1" || $business_use_notice_check eq "2") && ($requiredOS =~ $osversion) ) {

      if ($business_use_notice_check eq "1") {
         reporttext("\tBusiness Use Notice check is set for USA in $config_file\n") if $verbose;
      }
      if ($business_use_notice_check eq "2") {
         reporttext("\tBusiness Use Notice check is set for non-USA in $config_file\n") if $verbose;
      }

      if ($caption_final ne "") {
         reporttext("\tLegal notice caption is set to: $caption_final\n") if $verbose;
      }
      if ($notice_final ne "") {
         reporttext("\tLegal notice text is set to: $notice_final\n") if $verbose;
      }
      if ($logon_final  ne "") {
         reporttext("\tLogon prompt text is set to: $logon_final\n") if $verbose;
      }
      if ( ($business_use_notice_check eq "1" && $count >= 2) || ($business_use_notice_check eq "2" && $count >= 1) ) {
         reporttext("\tBusiness Use Notice meets wording requirement(s)\n");
      } else {
         reportfail($server, "Business Use Notice does not meet wording requirement(s)\n");
      }
   } else {
         reportwarn($server, "Business Use Notice check is disabled in $config_file\n");
   }

return();
}

####################################################################
#
# Description: check eventlog settings
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub eventlog_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey);
   my ($loglocation);
   my ($regKeyLocation);

   if ($localonly) {
      $UncPath = "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\EventLog\\";
   } else {
      $UncPath = "\\\\$server\\HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\EventLog\\";
   }

   $remKey = $Registry->{$UncPath};
   if (!$remKey) {
      reportsyserror($server, Win32->GetLastError(), "cannot connect to log file registry setting"); # %%%%FIXME
      return();
   }

   foreach my $logfile (('Application','Security','System')) {
   #   foreach my $logfile (('Security')) {
      my $logsubkey = $remKey->{$logfile . "\\"};
      my $maxlogsize = $logsubkey->GetValue("MaxSize");
      my $retention = $logsubkey->GetValue("Retention");
      $loglocation = $logsubkey->GetValue("File");
      $maxlogsize = (hex($maxlogsize))/(1024);  # kb
      $retention = (hex($retention))/(3600*24); # days

      my $retention_msg;
      my $retention_fail=0;

      if ($retention == 0) {
         $retention_msg = "Overwrite events as needed";
         $retention_fail = 1;
      } elsif ($retention > 365) {
         $retention_msg = "Do not overwrite (clear log manually)";
      } else {
         $retention_msg = "Overwrite events older than $retention days";
         if ($retention < $eventlog_retension) {
            $retention_fail = 1;
         }
      }

      if ($localonly) {
         my $logname = substr($logfile,0,3);
         $loglocation = "$systemroot\\system32\\config\\$logname"."Event.Evt";
      } else {
         # change the path to UNC convention
         $loglocation =~ s/\%SystemRoot\%/$systemroot/;
         $loglocation =~ s/:\\/\$\\/;
         $loglocation =~ s/:/\$/;
         my $logname = substr($logfile,0,3); # FIXME: this variable is never used
         $loglocation = "\\\\$server\\$loglocation";
      }

      #$regKeyLocation = $loglocation;

      my ($logfilesize);
      $logfilesize = -s "$loglocation";

      # number of kB
      $logfilesize = $logfilesize / 1024;

      # capacity
      my ($capacity);
      $capacity = int(($logfilesize / $maxlogsize) * 100);

      # retrieve full text of every message
      # calling Read() will call GetMessageText() automatically
      # $Win32::EventLog::GetMessageText = 1;

      my ($handle);

      # open eventlog
      $handle = Win32::EventLog->new("$logfile", $server);
      if (!$handle) {
         reportsyserror($server, Win32->GetLastError(), "cannot connect to EventLog $logfile"); # %%%%FIXME
         undef $remKey;
         return();
      }

      my ($totalRecord, $baseRecord, $lastRecord);

      # retrieve total and oldest record(s)
      $handle->GetNumber($totalRecord);
      $handle->GetOldest($baseRecord);

      $lastRecord = $baseRecord+$totalRecord;

      reportdebug("recs -> $totalRecord");
      reportdebug("base -> $baseRecord");
      reportdebug("last -> $lastRecord");

      my ($hashRef);

      #
      # read the base record entry
      #
      $handle->Read(EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ,
                                                     $baseRecord,
                                                     $hashRef);
      if (!$handle) { # FIXME: is handle really the right var to check here?  Don't you mean hashRef?
         reportsyserror($server, Win32->GetLastError(), "cannot read base record in EventLog $logfile"); # %%%%FIXME
         undef $remKey;
         return();
      }

      my ($baseDate);

      # retrieve date of creation
      $baseDate = $hashRef->{TimeGenerated};

      # retrieve message text
      # Win32::EventLog::GetMessageText($hashRef);
      reportdebug("entry for $baseRecord: $hashRef->{Message}");

      # calculate date
      my ($baseDay, $baseMonth, $baseYear) = (localtime ($hashRef->{TimeGenerated})) [3,4,5];
      $baseMonth++;
      $baseYear = $baseYear+1900;
      reportdebug("date for $baseRecord: $baseDay, $baseMonth, $baseYear");

      #
      # read the base last entry
      #
      $handle->Read(EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ,
                                                     $lastRecord-1,
                                                     $hashRef);
      if (!$handle) { # FIXME: is handle really the right var to check here?  Don't you mean hashRef?
         reportsyserror($server, Win32->GetLastError(), "cannot read last record in EventLog $logfile"); # %%%%FIXME
         undef $remKey;
         return();
      }

      my ($lastDate);

      # retrieve date of creation
      $lastDate = $hashRef->{TimeGenerated};

      # retrieve message text
      # Win32::EventLog::GetMessageText($hashRef);
      reportdebug("entry for $lastRecord: $hashRef->{Message}");

      # calculate date
      my ($lastDay, $lastMonth, $lastYear) = (localtime ($hashRef->{TimeGenerated})) [3,4,5];
      $lastMonth++;
      $lastYear = $lastYear+1900;
      reportdebug("date for $lastRecord: $lastDay, $lastMonth, $lastYear");

      #
      # calculate difference
      #
      my $difference = Delta_Days($baseYear, $baseMonth, $baseDay, $lastYear, $lastMonth, $lastDay);
      #reporttext("\tDifference between oldest and newst entry is: $difference days\n");
      reporttext("\t$logfile Event Log\n\t\t$loglocation is $logfilesize KB ($capacity"."% full)\n");
      reportfail($server, "$logfile is $logfilesize KB. $capacity"."% of capacity. Threshold is set to $eventlog_capacity"."%") if ( ($capacity > $eventlog_capacity) && ($difference < $eventlog_retension) );

      #if ($regKeyLocation) {
      #   reporterror($server,"Registry states location is $regKeyLocation");
      #}

      if ($verbose) {
         reporttext("\t\tMaximum size is $maxlogsize KB\n");
         reporttext("\t\tWrapping: $retention_msg\n");
      }
      if ($retention_fail) {
         reportfail($server,"Eventlog must be set to retain $eventlog_retension days of events or greater\n");
      }
   }

   return();
}


####################################################################
#
# Description: retrieve network adapter information
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
# The WMI routines are originally from Microsoft's Scripting
# Guide (Scriptomatic) available at
# http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
#
####################################################################

sub tcp_ip_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my @computers = ($server);
   foreach my $computer (@computers) {
      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      }

      my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);

      foreach my $objItem (in $colItems) {
         #reporttext("\tArpAlwaysSourceRoute: $objItem->{ArpAlwaysSourceRoute}\n");
         #reporttext("\tArpUseEtherSNAP: $objItem->{ArpUseEtherSNAP}\n");
         reporttext("\tInterface: $objItem->{Caption}\n");
         reporttext("\tDatabasePath: $objItem->{DatabasePath}\n");
         #reporttext("\tDeadGWDetectEnabled: $objItem->{DeadGWDetectEnabled}\n");
         reporttext("\tDefaultIPGateway: " . join("\t,", (in $objItem->{DefaultIPGateway})) . "\n");
         #reporttext("\tDefaultTOS: $objItem->{DefaultTOS}\n");
         #reporttext("\tDefaultTTL: $objItem->{DefaultTTL}\n");
         reporttext("\tDescription: $objItem->{Description}\n");
         reporttext("\tDHCPEnabled: $objItem->{DHCPEnabled}\n");
         if ( $objItem->{DHCPEnabled} == 1 ) {
            reporttext("\tDHCPLeaseExpires: $objItem->{DHCPLeaseExpires}\n");
            reporttext("\tDHCPLeaseObtained: $objItem->{DHCPLeaseObtained}\n");
            reporttext("\tDHCPServer: $objItem->{DHCPServer}\n");
         }
         reporttext("\tDNSDomain: $objItem->{DNSDomain}\n");
         reporttext("\tDNSDomainSuffixSearchOrder: " . join("\t,", (in $objItem->{DNSDomainSuffixSearchOrder})) . "\n");
         reporttext("\tDNSEnabledForWINSResolution: $objItem->{DNSEnabledForWINSResolution}\n");
         reporttext("\tDNSHostName: $objItem->{DNSHostName}\n");
         #reporttext("\tDNSServerSearchOrder: " . join("\t,", (in $objItem->{DNSServerSearchOrder})) . "\n");
         reporttext("\tDomainDNSRegistrationEnabled: $objItem->{DomainDNSRegistrationEnabled}\n");
         #reporttext("\tForwardBufferMemory: $objItem->{ForwardBufferMemory}\n");
         #reporttext("\tFullDNSRegistrationEnabled: $objItem->{FullDNSRegistrationEnabled}\n");
         #reporttext("\tGatewayCostMetric: " . join("\t,", (in $objItem->{GatewayCostMetric})) . "\n");
         #reporttext("\tIGMPLevel: $objItem->{IGMPLevel}\n");
         #reporttext("\tIndex: $objItem->{Index}\n");
         reporttext("\tIPAddress: " . join("\t,", (in $objItem->{IPAddress})) . "\n");
         #reporttext("\tIPConnectionMetric: $objItem->{IPConnectionMetric}\n");
         reporttext("\tIPEnabled: $objItem->{IPEnabled}\n");
         #reporttext("\tIPFilterSecurityEnabled: $objItem->{IPFilterSecurityEnabled}\n");
         #reporttext("\tIPPortSecurityEnabled: $objItem->{IPPortSecurityEnabled}\n");
         #reporttext("\tIPSecPermitIPProtocols: " . join("\t,", (in $objItem->{IPSecPermitIPProtocols})) . "\n");
         #reporttext("\tIPSecPermitTCPPorts: " . join("\t,", (in $objItem->{IPSecPermitTCPPorts})) . "\n");
         #reporttext("\tIPSecPermitUDPPorts: " . join("\t,", (in $objItem->{IPSecPermitUDPPorts})) . "\n");
         reporttext("\tIPSubnet: " . join("\t,", (in $objItem->{IPSubnet})) . "\n");
         #reporttext("\tIPUseZeroBroadcast: $objItem->{IPUseZeroBroadcast}\n");
         #reporttext("\tIPXAddress: $objItem->{IPXAddress}\n");
         #reporttext("\tIPXEnabled: $objItem->{IPXEnabled}\n");
         #reporttext("\tIPXFrameType: " . join("\t,", (in $objItem->{IPXFrameType})) . "\n");
         #reporttext("\tIPXMediaType: $objItem->{IPXMediaType}\n");
         #reporttext("\tIPXNetworkNumber: " . join("\t,", (in $objItem->{IPXNetworkNumber})) . "\n");
         #reporttext("\tIPXVirtualNetNumber: $objItem->{IPXVirtualNetNumber}\n");
         #reporttext("\tKeepAliveInterval: $objItem->{KeepAliveInterval}\n");
         #reporttext("\tKeepAliveTime: $objItem->{KeepAliveTime}\n");
         reporttext("\tMACAddress: $objItem->{MACAddress}\n");
         #reporttext("\tMTU: $objItem->{MTU}\n");
         #reporttext("\tNumForwardPackets: $objItem->{NumForwardPackets}\n");
         #reporttext("\tPMTUBHDetectEnabled: $objItem->{PMTUBHDetectEnabled}\n");
         #reporttext("\tPMTUDiscoveryEnabled: $objItem->{PMTUDiscoveryEnabled}\n");
         reporttext("\tServiceName: $objItem->{ServiceName}\n");
         reporttext("\tSettingID: $objItem->{SettingID}\n");
         #reporttext("\tTcpipNetbiosOptions: $objItem->{TcpipNetbiosOptions}\n");
         #reporttext("\tTcpMaxConnectRetransmissions: $objItem->{TcpMaxConnectRetransmissions}\n");
         #reporttext("\tTcpMaxDataRetransmissions: $objItem->{TcpMaxDataRetransmissions}\n");
         #reporttext("\tTcpNumConnections: $objItem->{TcpNumConnections}\n");
         #reporttext("\tTcpUseRFC1122UrgentPointer: $objItem->{TcpUseRFC1122UrgentPointer}\n");
         #reporttext("\tTcpWindowSize: $objItem->{TcpWindowSize}\n");
         if ( $objItem->{WINSPrimaryServer} ) {
            reporttext("\tWINSEnableLMHostsLookup: $objItem->{WINSEnableLMHostsLookup}\n");
            reporttext("\tWINSHostLookupFile: $objItem->{WINSHostLookupFile}\n");
            reporttext("\tWINSPrimaryServer: $objItem->{WINSPrimaryServer}\n");
            reporttext("\tWINSScopeID: $objItem->{WINSScopeID}\n");
            reporttext("\tWINSSecondaryServer: $objItem->{WINSSecondaryServer}\n");
         }
         reporttext("\t\n");
      }
   }
}

####################################################################
#
# Description: lanman plain-text network password check
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub lanman_password_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS);

   foreach $location (@lanman_encryption_settings) {
      ($value, $value_str) = NULL;
      ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS) = split(/:/, $location);

         if ($requiredOS =~ $osversion) {
             # Supposed to return: 1 is Enabled, 0 is Disabled, -1 is Undefined
            $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);

         if ($value eq "1") {
            $value_str = "Enabled";
         } elsif ($value eq "0") {
            $value_str = "Disabled";
         } else {
            $value_str = "Undefined";
         }

         if ($verbose) {
            reporttext("\t$regDescription is $value_str ($value)\n");
         }

         if ($value != $regValue) {
            if ($value == 1) {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  reportwarn($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               }
            } elsif ($value == 0) {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  reportwarn($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               }
            } else {
               if ( ($osversion eq "4.0" && $osservicepack eq "Service Pack 1") || ($osversion eq "4.0" && $osservicepack eq "Service Pack 2") || ($osversion eq "4.0" && $osservicepack eq "Service Pack 3") ) {
                  reportwarn($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  Under Windows NT $osversion $osservicepack SMB/CIFS plain-text password authentication is always enabled. Please upgrade to SP4 or higher\n");
               } else {
                  if ($regErrorLevel eq "FAIL") {
                     reportfail($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  } else {
                     reportwarn($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            }
         }
      }
   }

   undef $remKey;
   return();
}

####################################################################
#
# Description: storing of passwords using reversible encryption
#              in the domain (Supported on Windows 2000 and
#              2003 server)
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub reversible_encryption_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS);
   my (@List);

   if ($servertype =~ /Workstation/ || $servertype =~ /workstation/) {
      reporttext("\tINFO: This test does not apply to Workstations\n");
      return();
   } else {
      # only retrieve normal accounts, because otherwise a timeout will occur for MACHINE accounts
      if (!Win32::NetAdmin::GetUsers("\\\\$server", FILTER_NORMAL_ACCOUNT, \@List)) {
         reportsyserror($server, Win32::NetAdmin::GetError(), "unable to gather user listing from server");
      return();
      }
      foreach my $User ( @List ) {
         my $encrypted = &account_password_is_encrypted($User, $server, $osversion, $osservicepack, $osarch);
      }
   }
   return();
}

####################################################################
#
# Description: encrypted filesystem checks
#
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub encrypted_filesystem_policy ($$$$) {

# As of 05/25/2005 do not use this routine because the EFS policy does not always affect reversible password encryption.

   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS);

   if ($servertype =~ /Workstation/ || $servertype =~ /workstation/ ) {
      reporttext("\tINFO: This test does not apply to Workstations\n");
      return();
   } else {
      foreach $location (@encrypted_filesystem_settings) {
         ($value, $value_str) = NULL;
         ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS) = split(/:/, $location);

         if ($requiredOS =~ $osversion) {

            # Supposed to return: 1 is Enabled, 0 is Disabled, -1 is Undefined
            $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);

            # If the key exists, then encrypted filesystem is enabled.  If the key does not exist, then encrypted filesystem is disabled.

            if ($value gt "-1") {
               $value_str = "Enabled";
            } else {
               $value_str = "Undefined [and therefore Disabled]";
               # Set value to -1 because retrieve registry value returns NULL otherwise
               $value = -1;
            }

            if ($verbose) {
               reporttext("\t$regDescription is $value_str ($value)\n");
            }

            if ($value != $regValue) {
               if ($value == 0) {
                  if ($regErrorLevel eq "FAIL") {
                     reportfail($server, "Registry setting for [$regDescription] should be Undefined ($regValue) - the key should not exist.  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  } else {
                     reportwarn($server, "Registry setting for [$regDescription] should be Undefined ($regValue) - the key should not exist.  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: check guest and unauthenticated user access settings
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub guest_access_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredService, $requiredOS);
   my (%status);

   foreach $location (@registry_value_settings) {
      ($value, $value_str) = NULL;
      ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredService, $requiredOS) = split(/:/, $location);
         if ($requiredOS =~ $osversion) {

            if (!Win32::Service::GetStatus("\\\\$server","$requiredService", \%status)) {
               reporttext("\t$requiredService service does not appear to be installed on $server; skipping EventLog check!");
            } else {
               #reporttext("\t$requiredService is currently running\n") if ($status{CurrentState} == 4);
               #reporttext("\t$requiredService is not currently running\n") if ($status{CurrentState} == 1);

               # Supposed to return: 1 is Enabled, 0 is Disabled, -1 is Undefined
               $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);
               if ($value eq "1") {
                  $value_str = "Enabled";
               } elsif ($value eq "0") {
                  $value_str = "Disabled";
               } else {
                  $value_str = "Undefined";
               }

               if ($verbose) {
                  reporttext("\t$regDescription is $value_str ($value)\n");
               }

               if ($value != $regValue) {
                  if ($value == 1) {
                     if ($regErrorLevel eq "FAIL") {
                        reportfail($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                     } else {
                        if ($regErrorLevel ne "SKIP" ) {
                           reportwarn($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                        }
                     }
                  } elsif ($value == 0) {
                     if ($regErrorLevel eq "FAIL") {
                        reportfail($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                     } else {
                        if ($regErrorLevel ne "SKIP" ) {
                           reportwarn($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                        }
                     }
                  } else {
                     if ($regErrorLevel eq "FAIL") {
                        reportfail($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                     } else {
                        if ($regErrorLevel ne "SKIP" ) {
                           reportwarn($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                        }
                     }
                  }
               }
            }
         }
      }

   return();
}

####################################################################
#
# Description: retrieve registry setting from values
#
# Accepts: server
#          osversion
#          osservicepack
#          location (registry)
#          name (registry)
#          type (registry)
#
# Returns: NULL
#          or the stored value in a specific registry object value
#
####################################################################

sub retrieve_registry_value ($$$$$$) {
   my ($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType) = @_;
   my ($remKey);
   my ($value);
   my ($regValueData);

   if (!defined($regValueName) || $regValueName eq "") {
      reporterror($server,"unable to retrieve registry value for empty key");
      return();
   }

   if ($localonly) {
      $UncPath = "$regKeyLocation";
   } else {
      $UncPath = "\\\\$server\\$regKeyLocation";
   }
   $remKey = $Registry->{$UncPath};

   if (!$remKey) {
      reportsyserror($server, Win32::GetLastError(), "cannot open registry key $regKeyLocation");
      return();
   }

   $value = $remKey->GetValue("$regValueName");

   if (!defined($value)) {
      # Commented out the warning because it makes reversible_password_policy check appear broken
      # reportwarn($server, "could not retrieve registry value $regKeyLocation\\$regValueName");
      return(); # best guess for default value
   } else {
      return(hex($value));
   }
}

####################################################################
#
# Description: enumerate network shares
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub share_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my @shareList;
   my $format = '%-20s %-20s %-30s';

   if (!Win32::Lanman::NetShareEnum("\\\\$server", \@shareList)) {
      reportsyserror($server, Win32::Lanman::GetError(), "Failed to get share list."); # FIXME: use Win32::FormatMessage() ?
      return();
   }

   reporttext("\tNetwork Share Listing");
   reporttext("\t" . sprintf($format, "NetName", "Remark", "Path") . "\n");
   reporttext("\t" . sprintf($format, "--------------------", "--------------------", "------------------------------") . "\n");
   foreach my $share (@shareList) {
      my ($path);

      if (defined($share->{'path'})) {
         $path = $share->{'path'};
      } else {
         $path = "(Access to path denied)";
      }

      reporttext("\t" . sprintf($format, $share->{'netname'}, $share->{'remark'}, $path) . "\n");
   }
   reporttext("\t\n");

   return();
}

####################################################################
#
# Description: display operating system and hardware information
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
# The WMI routines are originally from Microsoft's Scripting
# Guide (Scriptomatic) available at
# http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
#
####################################################################

sub sysinfo_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my (@computers) = $server;

   foreach my $computer (@computers) {
      my ($objWMIService) = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_OperatingSystem","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            #reporttext("\tBootDevice: $objItem->{BootDevice}\n");
            reporttext("\tBuildNumber: $objItem->{BuildNumber}\n");
            #reporttext("\tBuildType: $objItem->{BuildType}\n");
            #reporttext("\tCaption: $objItem->{Caption}\n");
            #reporttext("\tCodeSet: $objItem->{CodeSet}\n");
            #reporttext("\tCountryCode: $objItem->{CountryCode}\n");
            #reporttext("\tCreationClassName: $objItem->{CreationClassName}\n");
            #reporttext("\tCSCreationClassName: $objItem->{CSCreationClassName}\n");
            #reporttext("\tCSDVersion: $objItem->{CSDVersion}\n");
            #reporttext("\tCSName: $objItem->{CSName}\n");
            #reporttext("\tCurrentTimeZone: $objItem->{CurrentTimeZone}\n");
            #reporttext("\tDataExecutionPrevention_32BitApplications: $objItem->{DataExecutionPrevention_32BitApplications}\n");
            #reporttext("\tDataExecutionPrevention_Available: $objItem->{DataExecutionPrevention_Available}\n");
            #reporttext("\tDataExecutionPrevention_Drivers: $objItem->{DataExecutionPrevention_Drivers}\n");
            #reporttext("\tDataExecutionPrevention_SupportPolicy: $objItem->{DataExecutionPrevention_SupportPolicy}\n");
            #reporttext("\tDebug: $objItem->{Debug}\n");
            #reporttext("\tDescription: $objItem->{Description}\n");
            #reporttext("\tDistributed: $objItem->{Distributed}\n");
            #reporttext("\tEncryptionLevel: $objItem->{EncryptionLevel}\n");
            #reporttext("\tForegroundApplicationBoost: $objItem->{ForegroundApplicationBoost}\n");
            reporttext("\tFreePhysicalMemory: $objItem->{FreePhysicalMemory}\n");
            reporttext("\tFreeSpaceInPagingFiles: $objItem->{FreeSpaceInPagingFiles}\n");
            reporttext("\tFreeVirtualMemory: $objItem->{FreeVirtualMemory}\n");

            # OS Install Date
            my $osInstallDate = $objItem->{InstallDate};

            #                            abcdefghijklmnopqrstuvwxy
            # format for Time Generated: 20060513175156.000000-240
            my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = split(//,$objItem->{InstallDate});
            my ($year) = $a.$b.$c.$d;
            my ($month) = $e.$f;
            my ($day) = $g.$h;
            my ($hour) = $i.$j;
            my ($min) = $k.$l;
            my ($sec) = $m.$n;
            $osInstallDate = "$year-$month-$day";

            reporttext("\tInstallDate: $osInstallDate\n");;
            #reporttext("\tInstallDate: $objItem->{InstallDate}\n");
            #reporttext("\tLargeSystemCache: $objItem->{LargeSystemCache}\n");

            ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = split(//,$objItem->{LastBootUpTime});
            ($year) = $a.$b.$c.$d;
            ($month) = $e.$f;
            ($day) = $g.$h;
            ($hour) = $i.$j;
            ($min) = $k.$l;
            ($sec) = $m.$n;
            my $osLastBootUpTime = "$year-$month-$day $hour:$min:$sec";

            reporttext("\tLastBootTime: $osLastBootUpTime\n");;

            #reporttext("\tLastBootUpTime: $objItem->{LastBootUpTime}\n");
            #reporttext("\tLocalDateTime: $objItem->{LocalDateTime}\n");
            reporttext("\tLocale: $objItem->{Locale}\n");
            reporttext("\tManufacturer: $objItem->{Manufacturer}\n");
            reporttext("\tMaxNumberOfProcesses: $objItem->{MaxNumberOfProcesses}\n");
            reporttext("\tMaxProcessMemorySize: $objItem->{MaxProcessMemorySize}\n");

            # OS String, SystemRoot and Partition
            my ($osString, $osSystemRoot, $osPartition) = split(/\|/, $objItem->{Name});

            reporttext("\tSystemOSName: $osString\n");
            reporttext("\tSystemRoot: $osSystemRoot\n");
            reporttext("\tSystemPartition: $osPartition\n");

            # reporttext("\tName: $objItem->{Name}\n");
            #reporttext("\tNumberOfLicensedUsers: $objItem->{NumberOfLicensedUsers}\n");
            reporttext("\tNumberOfProcesses: $objItem->{NumberOfProcesses}\n");
            reporttext("\tNumberOfUsers: $objItem->{NumberOfUsers}\n");
            reporttext("\tOrganization: $objItem->{Organization}\n");
            reporttext("\tOSLanguage: $objItem->{OSLanguage}\n");
            #reporttext("\tOSProductSuite: $objItem->{OSProductSuite}\n");
            #reporttext("\tOSType: $objItem->{OSType}\n");
            #reporttext("\tOtherTypeDescription: $objItem->{OtherTypeDescription}\n");
            #reporttext("\tPlusProductID: $objItem->{PlusProductID}\n");
            #reporttext("\tPlusVersionNumber: $objItem->{PlusVersionNumber}\n");
            #reporttext("\tPrimary: $objItem->{Primary}\n");
            #reporttext("\tProductType: $objItem->{ProductType}\n");
            #reporttext("\tQuantumLength: $objItem->{QuantumLength}\n");
            #reporttext("\tQuantumType: $objItem->{QuantumType}\n");
            reporttext("\tRegisteredUser: $objItem->{RegisteredUser}\n");
            reporttext("\tSerialNumber: $objItem->{SerialNumber}\n");

            # Service Pack
            my $osServicePack = ($objItem->{ServicePackMajorVersion});
            reporttext("\tServicePack: $osServicePack\n");

            #reporttext("\tServicePackMajorVersion: $objItem->{ServicePackMajorVersion}\n");
            #reporttext("\tServicePackMinorVersion: $objItem->{ServicePackMinorVersion}\n");
            #reporttext("\tSizeStoredInPagingFiles: $objItem->{SizeStoredInPagingFiles}\n");
            #reporttext("\tStatus: $objItem->{Status}\n");
            #reporttext("\tSuiteMask: $objItem->{SuiteMask}\n");
            #reporttext("\tSystemDevice: $objItem->{SystemDevice}\n");
            #reporttext("\tSystemDirectory: $objItem->{SystemDirectory}\n");
            #reporttext("\tSystemDrive: $objItem->{SystemDrive}\n");
            #reporttext("\tTotalSwapSpaceSize: $objItem->{TotalSwapSpaceSize}\n");
            #reporttext("\tTotalVirtualMemorySize: $objItem->{TotalVirtualMemorySize}\n");
            #reporttext("\tTotalVisibleMemorySize: $objItem->{TotalVisibleMemorySize}\n");

            # OS Version
            my ($osVersionPrimary, $osVersionSecondary) = split(/\./, $objItem->{Version});
            my $osVersion = "$osVersionPrimary.$osVersionSecondary";

            reporttext("\tOS Version: $osVersion\n");

            #reporttext("\tVersion: $objItem->{Version}\n");
            #reporttext("\tWindowsDirectory: $objItem->{WindowsDirectory}\n");
            #reporttext("\n");
         }
      }
   }

   reporttext("\n");

   foreach my $computer (@computers) {
      my ($objWMIService) = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Processor","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            #reporttext("\tAddressWidth: $objItem->{AddressWidth}\n");
            #reporttext("\tArchitecture: $objItem->{Architecture}\n");
            #reporttext("\tAvailability: $objItem->{Availability}\n");
            #reporttext("\tCaption: $objItem->{Caption}\n");
            #reporttext("\tConfigManagerErrorCode: $objItem->{ConfigManagerErrorCode}\n");
            #reporttext("\tConfigManagerUserConfig: $objItem->{ConfigManagerUserConfig}\n");
            #reporttext("\tCpuStatus: $objItem->{CpuStatus}\n");
            #reporttext("\tCreationClassName: $objItem->{CreationClassName}\n");
            reporttext("\tCurrentClockSpeed: $objItem->{CurrentClockSpeed}\n");
            reporttext("\tCurrentVoltage: $objItem->{CurrentVoltage}\n");
            #reporttext("\tDataWidth: $objItem->{DataWidth}\n");

            # OS Architecture
            my ($osArchitecture) = split(/ /, $objItem->{Description});
            reporttext("\tDescription: $objItem->{Description}\n");

            #reporttext("\tDescription: $objItem->{Description}\n");
            #reporttext("\tDeviceID: $objItem->{DeviceID}\n");
            #reporttext("\tErrorCleared: $objItem->{ErrorCleared}\n");
            #reporttext("\tErrorDescription: $objItem->{ErrorDescription}\n");
            #reporttext("\tExtClock: $objItem->{ExtClock}\n");
            #reporttext("\tFamily: $objItem->{Family}\n");
            #reporttext("\tInstallDate: $objItem->{InstallDate}\n");
            #reporttext("\tL2CacheSize: $objItem->{L2CacheSize}\n");
            #reporttext("\tL2CacheSpeed: $objItem->{L2CacheSpeed}\n");
            #reporttext("\tLastErrorCode: $objItem->{LastErrorCode}\n");
            #reporttext("\tLevel: $objItem->{Level}\n");
            reporttext("\tLoadPercentage: $objItem->{LoadPercentage}\n");
            reporttext("\tManufacturer: $objItem->{Manufacturer}\n");
            reporttext("\tMaxClockSpeed: $objItem->{MaxClockSpeed}\n");
            reporttext("\tProcessorName: $objItem->{Name}\n");
            #reporttext("\tOtherFamilyDescription: $objItem->{OtherFamilyDescription}\n");
            #reporttext("\tPNPDeviceID: $objItem->{PNPDeviceID}\n");
            #reporttext("\tPowerManagementCapabilities: " . join(",", (in $objItem->{PowerManagementCapabilities})) . "\n");
            #reporttext("\tPowerManagementSupported: $objItem->{PowerManagementSupported}\n");
            reporttext("\tProcessorId: $objItem->{ProcessorId}\n");
            reporttext("\tProcessorType: $objItem->{ProcessorType}\n");
            reporttext("\tRevision: $objItem->{Revision}\n");
            #reporttext("\tRole: $objItem->{Role}\n");
            #reporttext("\tSocketDesignation: $objItem->{SocketDesignation}\n");
            reporttext("\tStatus: $objItem->{Status}\n");
            #reporttext("\tStatusInfo: $objItem->{StatusInfo}\n");
            reporttext("\tStepping: $objItem->{Stepping}\n");
            #reporttext("\tSystemCreationClassName: $objItem->{SystemCreationClassName}\n");
            reporttext("\tSystemName: $objItem->{SystemName}\n");
            #reporttext("\tUniqueId: $objItem->{UniqueId}\n");
            #reporttext("\tUpgradeMethod: $objItem->{UpgradeMethod}\n");
            #reporttext("\tVersion: $objItem->{Version}\n");
            #reporttext("\tVoltageCaps: $objItem->{VoltageCaps}\n");
            #reporttext("\n");
         }
      }
   }

   return ();
}

####################################################################
#
# Description: check network settings in registry
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub list_network_registry_settings ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS);

   my ($regValue1, $regValue2);

   foreach $location (@network_registry_value_settings) {

      ($value, $value_str) = NULL;
      ($regKeyLocation, $regValueName, $regValueType, $regValue, $regErrorLevel, $regDescription, $requiredOS) = split(/:/, $location);

         if ($requiredOS =~ $osversion) {
            #reporttext("\n");
            # Supposed to return: 1 is Enabled, 0 is Disabled, -1 is Undefined
            $value = retrieve_registry_value($server, $osversion, $osservicepack, $regKeyLocation, $regValueName, $regValueType);

         if ($value eq "2") {
            $value_str = "Enabled";
         } elsif ($value eq "1") {
            $value_str = "Enabled";
         } elsif ($value eq "0") {
            $value_str = "Disabled";
         } else {
            $value_str = "Undefined";
         }

         if ($verbose) {
            reporttext("\t$regDescription is $value_str ($value)\n");
         }

         if ($regValue =~ m/\|/) {
            ($regValue1, $regValue2) = split(/\|/, $regValue);
         }

         if ($value == $regValue1) {
            $regValue = $regValue1;
         }

         if ($value == $regValue2) {
            $regValue = $regValue2;
         }

         if ($value != $regValue) {
            if ($value == 2) {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  if ($regErrorLevel ne "SKIP" ) {
                     reportwarn($server, "Registry setting for [$regDescription] should be Disabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            } elsif ($value == 1) {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  if ($regErrorLevel ne "SKIP" ) {
                     reportwarn($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            } elsif ($value == 0) {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  if ($regErrorLevel ne "SKIP" ) {
                     reportwarn($server, "Registry setting for [$regDescription] should be Enabled ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            } else {
               if ($regErrorLevel eq "FAIL") {
                  reportfail($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
               } else {
                  if ($regErrorLevel ne "SKIP" ) {
                     reportwarn($server, "Registry setting for [$regDescription] should be ($regValue).  $regKeyLocation\\$regValueName currently $value_str ($value)\n");
                  }
               }
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: check service status in registry
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: -1 if not found/not installed
#           0 if disabled
#           1 if enabled
####################################################################

sub is_service_enabled ($$$$$) {
   my ($server, $osversion, $osservicepack, $osarch, $servicename) = @_;
   my ($remKey, $location);
   my ($value, $value_str);
   my ($UncPath);
   my ($serviceKey, $serviceStart);

   foreach my $servicePath (@ms_service_registry_keys) {
      if ($localonly) {
         $UncPath = "$servicePath";
      } else {
         $UncPath = "\\\\$server\\$servicePath";
      }
      $remKey = $Registry->{$UncPath};

      if (!$remKey) {
         reportsyserror($server, Win32->GetLastError(), "unable to retrieve services registry information"); # %%%%FIXME
      } else {
         my @subkeynames = $remKey->SubKeyNames;
         foreach my $service (@subkeynames) {
            reportdebug("service -> $service");
            if ($service =~ /$servicename/) {
               reportdebug("$service contains $servicename");
               $UncPath = "$UncPath$service";
               reportdebug("UncPath -> $UncPath");
               $serviceKey = $Registry->{$UncPath};
               $serviceStart = $serviceKey->GetValue("Start");

               # Service Settings:
               #
               # Disabled  = REG_DWORD = 0x4 (4)
               # Manual    = REG_DWORD = 0x3 (3)
               # Automatic = REG_DWORD = 0x2 (2)

               if (hex($serviceStart)==4) {
                  reportdebug("$server,$service is set to Disabled (4)");
                  return(0);
               } else {
                  if (hex($serviceStart)==3) {
                     reportdebug("$server,$service is set to Manual startup (3)");
                     return(0);
                  } else {
                     if (hex($serviceStart)==2) {
                        reportdebug("$server,$service is set to Automatic startup (2)");
                        return(1);
                     } else {
                        reportdebug("$server,$service is set to Unknown startup ()");
                        return(-1);
                     }
                  }
               }
            }
         }
      }
   }

   return(-1);
}

####################################################################
#
# Description: check network open ports/services
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
####################################################################

sub netstat_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;

   my $cmd = "netstat.exe";
   my $arg = "-an"; # don't use -ano option

   if ($localonly) {
      my $pid = open(NETSTAT, "$cmd $arg |");
      while ( <NETSTAT> ) {
         strip_item($_);
         reporttext("\t$_");
      }
   } else {
      reporttext("\tINFO: This test can only be run in -localonly mode\n");
   }
   reporttext("\n");

   return();
}


####################################################################
#
# Description: check the system eventlog for system restarts
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
# For Windows Event Codes see: http://support.microsoft.com/default.aspx?scid=kb;en-us;196452&sd=tech
#
####################################################################

sub system_restart_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($accounts, @services);
   my ($account_name, $service_name);
   my ($account);

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my @computers = ($server);

   foreach my $computer (@computers) {
      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_NTLogEvent Where LogFile = 'System'","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            if ( $objItem->{EventCode} == 6005 ) {
               #reporttext("\tCategory: $objItem->{Category}\n");
               #reporttext("\tCategory String: $objItem->{CategoryString}\n");
               reporttext("\tComputer Name: $objItem->{ComputerName}\n");
               #reporttext("\tData: " . join(",", (in $objItem->{Data})) . "\n");
               #reporttext("\tEvent Code: $objItem->{EventCode},");
               #reporttext("\tEvent Identifier: $objItem->{EventIdentifier}\n");
               #reporttext("\tEvent Type: $objItem->{EventType}\n");
               #reporttext("\tInsertion Strings: " . join(",", (in $objItem->{InsertionStrings})) . "\n");
               reporttext("\tLogfile: $objItem->{Logfile}\n");
               my ($message) = "$objItem->{Message}";
               $message =~ s/\e\f\t\r\n\W//; # remove escape, forfeed, tab, return and newline characters in message
               chop($message);
               reporttext("\tMessage: $message\n");
               #reporttext("\tMessage: $objItem->{Message}\n");
               reporttext("\tRecord Number: $objItem->{RecordNumber}\n");
               #reporttext("\tSource Name: $objItem->{SourceName}\n");

               #                            abcdefghijklmnopqrstuvwxy
               # format for Time Generated: 20060513175156.000000-240
               my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m,$n) = split(//,$objItem->{TimeGenerated});
               my ($year) = $a.$b.$c.$d;
               my ($month) = $e.$f;
               my ($day) = $g.$h;
               my ($hour) = $i.$j;
               my ($min) = $k.$l;
               my ($sec) = $m.$n;
               reporttext("\tTime Generated: $year-$month-$day $hour:$min:$sec\n");
               #reporttext("\tTime Written: $objItem->{TimeWritten}\n");
               #reporttext("\tType: $objItem->{Type}\n");
               #reporttext("\tUser: $objItem->{User}\n");
               reporttext("\n");
            }
         }
      }
   }

   return();
}

####################################################################
#
# Description: check the system eventlog for system restarts
#
# Accepts: server
#          osversion
#          osservicepack
#          osarch
#
# Returns: nothing
#
# Most of these applications are listed in "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
#
# The WMI routines are originally from Microsoft's Scripting
# Guide (Scriptomatic) available at
# http://www.microsoft.com/technet/scriptcenter/tools/scripto2.mspx
#
####################################################################

sub system_installed_application_policy ($$$$) {
   my ($server, $osversion, $osservicepack, $osarch) = @_;
   my ($accounts, @services);
   my ($account_name, $service_name);
   my ($account);

   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;

   my @computers = ($server);

   foreach my $computer (@computers) {
      my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");
      if (!$objWMIService) {
         reportsyserror($server, Win32->GetLastError(), "WMI connection failed"); # %%%%FIXME
         return();
      } else {
         my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Product","WQL",wbemFlagReturnImmediately | wbemFlagForwardOnly);
         foreach my $objItem (in $colItems) {
            my ($caption) = $objItem->{Caption};
            reporttext("\tApplication: $objItem->{Caption}\n");
            my ($description) = $objItem->{Description};
            if ($description ne $caption) {
               reporttext("\tDescription: $objItem->{Description}\n");
            }
            reporttext("\tIdentifyingNumber: $objItem->{IdentifyingNumber}\n");
            reporttext("\tInstallDate: $objItem->{InstallDate}\n");
            #reporttext("\tInstallDate2: $objItem->{InstallDate2}\n");
            reporttext("\tInstallLocation: $objItem->{InstallLocation}\n");
            #reporttext("\tInstallState: $objItem->{InstallState}\n");
            #reporttext("\tName: $objItem->{Name}\n");
            #reporttext("\tPackageCache: $objItem->{PackageCache}\n");
            #reporttext("\tSKUNumber: $objItem->{SKUNumber}\n");
            reporttext("\tVendor: $objItem->{Vendor}\n");
            reporttext("\tVersion: $objItem->{Version}\n");
            reporttext("\n");
         }
      }
   }

   return();
}
