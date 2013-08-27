#
# Usage of the NTCheck tool
#

1. Open a command prompt window with administrative rights 
2. run sepntcheck.exe -nopdc -server localhost -nogui

#
# Steps - create a base Windows Server 2008 image
#

1. Windows update
   Go to Start -> Control Panel -> System and Security -> Windows Update
   
2. Install Cygwin

3. Fix unexpected blue screen issue (From SCE support community Q16E)  
   Open a command prompt window with administrative rights (Start -> All Programs -> Accessories -> Right Click on "Command Prompt" -> Run as Administrator)
   Run "bcdedit /set {default} bootstatuspolicy ignoreallfailures".

4. Make the image comply with ITCS104
   Change Audit Policy
   1) Go to Start -> Administrative Tools -> Local Security Policy
   2) Click Local Policies -> Audit Policy
   3) Right click "Audit system events", open "Properties", select "failure" checkbox, then click "ok".
   4) Right click "Audit logon events", open "Properties", select "success" and "failure" checkbox, then click "ok".
   5) Right click "Audit object access", open "Properties", select "failure" checkbox, then click "ok".
   6) Right click "Audit Privilege Use", open "Properties", select "success" and "failure" checkbox, then click "ok".
   7) Right click "Audit Policy Change", open "Properties", select "success" and "failure" checkbox, then click "ok".
   8) Right click "Audit account management", open "Properties", select "success" and "failure" checkbox, then click "ok".
   9) Right click "Audit Directory Service Access", open "Properties", select "failure" checkbox, then click "ok".
     
   Change Account Policy
   1) Go to Start -> Administrative Tools -> Local Security Policy
   2) Click Account Policies -> Password Policy
   3) Double click "Minimum password age" and set to 1 day
   4) Double click "Minimum password length" and set to 8
   5) Double click "Enforce password history" and set to 8
   6) Click Account Policies -> Account Lockout Policy
   7) Double click "Account lockout threshold" and set to 5
   8) Double click "Account lockout duration" and set to 0
   
   Password expires setting
   1) Go to Start -> Administrative Tools -> Computer Management
   2) Click Users and Groups -> Users
   3) In right panel, right click your account and select Properties
   4) Un-Select "Password Never Expires" checkbox
   
   Set Eventlog to retain 90 days
   1) Run "regedit"
   2) Go to HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog\Application
      Double click "Retention", select Decimal and set the value data to 8000000
   3) Go to HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog\System
      Double click "Retention", select Decimal and set the value data to 8000000
   4) Go to HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\EventLog\Security
      Double click "Retention", select Decimal and set the value data to 8000000
      Double click "MaxSize", select Decimal and set the value data to 22675456
      
   Set Security event log threshold
   1) Run "gpedit.msc"
   2) Click Administrative Templates -> Windows Components -> Event Log Service -> Security
   3) Double click "Maximum Log Size (KB)", select "Enabled", then click ok

5. Mount a new disk named E:\ and add full control of this disk to "users" group. 
   Make sure for the provisioned instance, the user has the write permission on it.
   
6. Windows firewall rule to block ports 135, 139, 445

7. Turned off File/Print sharing (tcpip config panel - uncheck box)
      
8. Capture image from SCE portal

9. After capture image, modify the image asset, replace scripts.txt, run_at_first_prov.txt
   and add powershell.ps1
   