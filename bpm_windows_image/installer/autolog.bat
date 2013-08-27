@echo off
title Autolog
mode con lines=45
mode con cols=111
SETLOCAL
echo WARNING:  Upon successful execution of this script, the instance will shut down in 5 minutes. To abort the shutdown, execute the 'shutdown /a' command from the command prompt when the System shutdown window appears.
echo.
SET REGEXIST=1
SET LOGFILEPATH=c:\windows\temp\saveImage.log
SET AUTOLOGPATH=COM1
set AUTOLOG_DONE=C:\cygwin\autolog.done
set AUTOLOG_FAIL=C:\cygwin\autolog.fail

if exist "C:\Windows\Temp\AUTOLOGENABLED" (
	del /F C:\Windows\Temp\AUTOLOGENABLED
)

REM delete any shared mounts
echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "net use \\%computername%\C$ /delete /y". > %LOGFILEPATH%
net use \\%computername%\C$ /delete /y > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
	echo [%date% %time%] WARNING Autolog DTCWI0009W: Failed to execute command "net use \\%computername%\C$ /delete", Error code: %ERRORLEVEL%, Error message: >> %LOGFILEPATH%
	net use \\%computername%\C$ /delete /y >> %LOGFILEPATH% 2>&1
)

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonOn" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonOn"') DO (

		if NOT "%%A"=="0x0" ( 
			call :ERRMSG "Shut down event tracker" "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" "ShutdownReasonOn" '0' %%A
		)
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Shut down event tracker: ShutdownReasonOn" is off. >> %LOGFILEPATH%

SET REGEXIST=1
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonUI" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" /v "ShutdownReasonUI"') DO (
		if NOT %%A==0x0 (
			call :ERRMSG "Shut down event tracker" "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" "ShutdownReasonUI" '0' %%A
		)
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Shut down event tracker: ShutdownReasonUI" is off. >> %LOGFILEPATH%

SET REGEXIST=1
reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" /v "legalnoticecaption" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" /v "legalnoticecaption"') DO (
		call :ERRMSG "Legal use notice" "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" "legalnoticecaption" blank %%A
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Legal use notice: legalnoticecaption" is off. >> %LOGFILEPATH%

SET REGEXIST=1
reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" /v "legalnoticetext" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" /v "legalnoticetext"') DO (
		call :ERRMSG "Legal use notice" "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system" "legalnoticetext" blank %%A
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Legal use notice: legalnoticetext" is off. >> %LOGFILEPATH%

SET REGEXIST=1
reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "legalnoticecaption" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "legalnoticecaption"') DO (
		call :ERRMSG "Legal use notice" "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "legalnoticecaption" blank %%A
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Legal use notice: legalnoticecaption" is off. >> %LOGFILEPATH%

SET REGEXIST=1
reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "legalnoticetext" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
	FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "legalnoticetext"') DO (
		call :ERRMSG "Legal use notice" "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" "legalnoticetext" blank %%A
	)
)
echo [%date% %time%] INFO Autolog DTCWI0002I: Windows pop-up "Legal use notice: legalnoticetext" is off. >> %LOGFILEPATH%

FOR /F "tokens=3" %%A IN ('cmd /c cscript //nologo c:\windows\system32\slmgr.vbs /dlv ^| findstr "Status"') DO (
	IF NOT %%A == Licensed (

		echo [%date% %time%] ERROR Autolog DTCWI0010E: License has not been activated for the instance. >> %LOGFILEPATH%
		echo License has not been activated for this instance. Child instance[s] formed from this parent instance may not be accessible. Please activate the license and again execute autolog.
		echo To activate license use the following steps:-
		echo.
		echo 1. Turn off windows firewall:
		echo    a. Click 'Start', click 'Control Panel', click 'Windows Firewall', click 'Turn Windows Firewall on or off'
		echo    b. You will get a pop up window with two options. Click on 'Continue'. If you don't get a pop up then proceed to step c.
		echo    c. On the 'General' tab, select 'Off' and click 'Ok' to turn off firewall.
		echo.
		echo 2. Synchronize time:
		echo    a. From 'Control Panel' open 'Date and Time'. 
		echo    b. From the 'Internet time' tab, click on 'Change settings'.
		echo    c. You will get a pop up window with two options. Click on 'Continue'. If you don't get a pop up then proceed to step d.
		echo    d. Select the 'time.windows.com' server and click 'Update now'.
		echo.
		echo 3. Activate license:
		echo    a. Click 'Start'. Right click 'Command Prompt' and then click 'Run as Administrator'.
		echo    b. You will get a pop up window with two options. Click on 'Continue'. If you don't get a pop up then proceed to step c.
		echo    c. Execute the command slmgr.vbs /ato to activate the license for the particular instance.
		echo.
		echo 4. Turn on windows firewall:
		echo    a. Click 'Start', click 'Control Panel', click 'Windows Firewall', click 'Turn Windows Firewall on or off'
		echo    b. You will get a pop up window with two options. Click on 'Continue'. If you don't get a pop up then proceed to step c.
		echo    c. On the 'General' tab, select 'On' and click 'Ok' to turn on firewall.
		echo.
		echo [%date% %time%] AUTOLOG FAILED > %AUTOLOG_FAIL%
		EXIT
	)ELSE (
		echo [%date% %time%] INFO Autolog DTCWI0011I: License is activated for the instance. >> %LOGFILEPATH%
	)
)

REM -------------  Set autologon entries in registry  --------------

set count=1
SET REGEXIST=1
SET isDomainController=0

	reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" > NUL 2>&1 ||SET REGEXIST=0
	if %REGEXIST%==1 (
		FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName"') DO (
			if NOT %%A==WORKGROUP (
				SET isDomainController=1
			)
		)
	)


if %isDomainController%==1 (
	echo A Domain Controller is detected to be running on this machine. 
	echo Enter the administrator password (It is the password provided at dcpromo.exe unless changed later^):
) else (
	echo Enter the administrator password (It is the same password provided at instance provisioning unless changed later^):
)


:chkPassword
@REM for /F "tokens=*" %%I in ('"c:\bat\hidepass.exe"') do set PROMPT_STDOUT=%%I
@REM for /F "tokens=2" %%I in ("%PROMPT_STDOUT%") do set pwd=%%I
set pwd=%1
net use  \\%computername%\C$ /user:administrator "%pwd%" > NUL 2>&1

IF %ERRORLEVEL% NEQ 0 (
	IF %count% == 3 (
 		echo.
 		echo Incorrect password.
		echo The maximum number of password attempts has been exceeded, autolog failed to complete.  Please try again or post to the support forum if you continue to have problems.
		echo [%date% %time%] ERROR Autolog DTCWI0019E: You have exceeded the maximum attempts for password. >> %LOGFILEPATH%
		echo [%date% %time%] AUTOLOG FAILED > %AUTOLOG_FAIL%
		EXIT 16
	)

	echo.
	echo Incorrect password, please try again.
	echo [%date% %time%] ERROR Autolog DTCWI0005E: Password entered for administrator is incorrect. >> %LOGFILEPATH%

	set /A count+=1	
	echo [%date% %time%] AUTOLOG FAILED > %AUTOLOG_FAIL%
	EXIT 16
	@REM GOTO chkPassword
)
echo [%date% %time%] INFO Autolog DTCWI0006I: Password entered for administrator is correct. >> %LOGFILEPATH%

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "net use \\%computername%\C$ /delete /y". >> %LOGFILEPATH%
net use \\%computername%\C$ /delete /y > NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
	echo [%date% %time%] ERROR Autolog DTCWI0007E: Failed to execute command "net use \\%computername%\C$ /delete", Error code: %ERRORLEVEL%, Error message: >> %LOGFILEPATH%
	net use \\%computername%\C$ /delete /y >> %LOGFILEPATH% 2>&1
)
	
set regset=false

set imageCaptureChoice=SYSPREPED
echo Select the mode of image capture:
echo 1) Press 1, if you want to capture an image with the System Prepartion Tool (Sysprep), which is the default mode.
echo 2) Press 2, if you want to capture an image without invoking the Sysprep tool, for example, when you want to retain the same SID in the children instance. Refer to the User's Guide for more information about the non-Sysprep capture.
echo	Note: The non-Sysprep capture is not a standard solution supported by Microsoft. For more information on this restriction please refer to the User's Guide
@REM CHOICE /C 12 /N
@REM if errorlevel 2 goto 2
@REM if errorlevel 1 goto 1
goto 1
:1
set imageCaptureChoice=SYSPREPED
goto process
:2
set imageCaptureChoice=NON-SYSPREPED
goto process
:process
echo You have chosen to capture %imageCaptureChoice% image

echo querying date format used in Locale >> %LOGFILEPATH%

set sdate=01/01/1980
SET REGEXIST=1
set Key="HKEY_CURRENT_USER\Control Panel\International"
reg query %key% /v "sShortDate" > NUL 2>&1 ||SET REGEXIST=0
if %REGEXIST%==1 (
for /F "tokens=3" %%a in ('reg query %Key% ^| find /i "sShortDate"') do set SDateFormat=%%a
)

echo %SDateFormat% | findstr /c:/ >> %LOGFILEPATH%
IF %ERRORLEVEL% EQU 0 (
		
		set delimeter=/
		goto delimatenow
		
) 

echo %SDateFormat% | findstr /c:- >> %LOGFILEPATH%
IF %ERRORLEVEL% EQU 0 (
		
		set delimeter=-
		goto delimatenow
) 
echo %SDateFormat% | findstr /c:. >> %LOGFILEPATH%
IF %ERRORLEVEL% EQU 0 (
		
		set delimeter=.
		goto delimatenow
) 
 
:delimatenow

for /f "tokens=1-3,* delims=%delimeter%" %%G in ("%SDateFormat%") do (

if %%I==yyyy (
		
		set sdate=01/01/1980
) ELSE (
	if %%G==yyyy (
		
		set sdate=1980/01/01
		     ) ELSE (
		if %%H==yyyy (
	
		set sdate=01/1980/01
			     )
	                    )
       )
)
echo date to be used in create schtask is %sdate% >> %LOGFILEPATH%

SET REGEXIST=1
SET isDomainController=0
if %imageCaptureChoice%==SYSPREPED (
	reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName" > NUL 2>&1 ||SET REGEXIST=0
	if %REGEXIST%==1 (
		FOR /F "tokens=3" %%A IN ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DefaultDomainName"') DO (
			if NOT %%A==WORKGROUP (
				echo [%date% %time%] ERROR Autolog DTCWI0003E: Instance is a domain controller >> %LOGFILEPATH%
				SET isDomainController=1
			)
		)
	)
)

if %isDomainController%==1 (
		echo WARNING: Instance is a domain controller, the subsequent child instance provisioning will fail because the captured image will be an unusable image
		echo Do you still want to continue?
		echo Press 1 to abort/exit, this is the default option
		echo Press 2 to continue
		CHOICE /C 12 /N
		if errorlevel 2 goto two
		if errorlevel 1 goto one
		:one
			EXIT 17
		:two
			goto process1
) else (
	goto process1
)

:process1
echo Enabling autologon...

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /delete". >> %LOGFILEPATH%
schtasks /delete /f /tn AutologEnable >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /create". >> %LOGFILEPATH%
schtasks /create /tn AutologEnable /tr "cmd /C reg add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\" /v DefaultPassword /t REG_SZ /d \"%pwd%\" /f" /sc ONCE /sd %sdate% /st 01:00:00 /ru Administrator /rp "%pwd%" >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /run". >> %LOGFILEPATH%
schtasks /run /tn AutologEnable >> %LOGFILEPATH% 2>&1
sleep 5s

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /change". >> %LOGFILEPATH%
schtasks /change /tn AutologEnable /tr "cmd /C reg add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\" /v AutoAdminLogon /t REG_SZ /d \"1\" /f" /ru Administrator /rp "%pwd%" >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /run". >> %LOGFILEPATH%
schtasks /run /tn AutologEnable >> %LOGFILEPATH% 2>&1
sleep 5s

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /change". >> %LOGFILEPATH%
schtasks /change /tn AutologEnable /tr "cmd /C reg add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\" /v DefaultUserName /t REG_SZ /d \"Administrator\" /f" /ru Administrator /rp "%pwd%" >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /run". >> %LOGFILEPATH%
schtasks /run /tn AutologEnable >> %LOGFILEPATH% 2>&1
sleep 5s

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /change". >> %LOGFILEPATH%
schtasks /change /tn AutologEnable /tr "cmd /C reg add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image\" /v CaptureType /t REG_SZ /d \"%imageCaptureChoice%\" /f" /ru Administrator /rp "%pwd%" >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /run". >> %LOGFILEPATH%
schtasks /run /tn AutologEnable >> %LOGFILEPATH% 2>&1
sleep 5s

if %imageCaptureChoice%==NON-SYSPREPED (
	echo [%date% %time%] INFO Autolog DTCWI0004I: Image captured will be a non-syspreped image >> %LOGFILEPATH%
	if exist "C:\cloud\CustomAutolog.bat" (
		echo [%date% %time%] INFO Autolog DTCWI0004I: Executing CustomAutolog.bat. >> %LOGFILEPATH%
		call "c:\cloud\CustomAutolog.bat" "%pwd%"
	)
)

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /delete". >> %LOGFILEPATH%
schtasks /delete /f /tn AutologEnable >> %LOGFILEPATH% 2>&1


@REM FOR /F "tokens=3" %%A IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon') DO (
@REM 	if %%A==0 (
@REM 		echo [%date% %time%] ERROR Autolog DTCWI0003E: Failed to enable autologon. Reason: AutoAdminLogon is not set to 1. Value set is %%A. >> %LOGFILEPATH%
@REM 		set regset=false
@REM 	)ELSE (
@REM 		echo [%date% %time%] INFO Autolog DTCWI0004I: Autologon parameter set. Message: AutoAdminLogon is set to required value 1. >> %LOGFILEPATH%
@REM 		set regset=true
@REM 	)
@REM )

@REM FOR /F "tokens=3" %%A IN ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName') DO (
@REM 	if NOT %%A==Administrator (
@REM 		echo [%date% %time%] ERROR Autolog DTCWI0003E: Failed to enable autologon. Reason: DefaultUserName for Autologon is not set to Administrator. Value set is %%A. >> %LOGFILEPATH%
@REM 		set regset=false
@REM 	)ELSE (
@REM 		echo [%date% %time%] INFO Autolog DTCWI0004I: Autologon parameter set. Message: DefaultUserName for Autologon is set to required value Administrator. >> %LOGFILEPATH%
@REM 	)
@REM )

@REM IF %regset% == false (
@REM 	echo Failed to enable autologon.
@REM 	echo [%date% %time%] ERROR Autolog DTCWI0003E: Failed to enable autologon. >> %LOGFILEPATH%
@REM 	echo [%date% %time%] AUTOLOG FAILED > %AUTOLOG_FAIL%
@REM 	EXIT 3
@REM )

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /delete". >> %LOGFILEPATH%
schtasks /delete /f /tn CheckAutolog >> %LOGFILEPATH% 2>&1

echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "schtasks /create". >> %LOGFILEPATH%
schtasks /create /sc ONSTART /tn CheckAutolog /tr "cmd /C echo [%date% %time%] INFO Autolog DTCWI0016I: Autolog.bat was executed >> %AUTOLOGPATH% & schtasks /delete /f /tn CheckAutolog" /ru Administrator /rp "%pwd%" >> %LOGFILEPATH% 2>&1

@REM echo [%date% %time%] INFO Autolog DTCWI0008I: Executing command "%SystemRoot%\system32\shutdown /t 300 /s". >> %LOGFILEPATH%
@REM %SystemRoot%\system32\shutdown /t 300 /s

echo [%date% %time%] INFO Autolog: Autolog is done. >> %LOGFILEPATH%
echo Enabling autologon done.

REM ---- At this stage, autolog.bat has been executed successully ----
echo "" > C:\Windows\Temp\AUTOLOGENABLED
echo [%date% %time%] AUTOLOG DONE > %AUTOLOG_DONE%
EXIT

:ERRMSG
echo [%date% %time%] ERROR Autolog DTCWI0001E: Windows pop-up %1 is on. Associated registry key: %2\%3, value %5. >> %LOGFILEPATH%
echo.
echo %1 is on. It may cause image capture to fail. Please disable it and try again.
echo To disable it one can use the following steps. It is recommended that you backup the registry before making any changes to it :-
echo.
echo 1. Type regedit in RUN dialog box and press Enter.
echo 2. It'll open Registry Editor. Navigate to: %2
echo 3. Look for value: %3 and set it to %4
echo.
echo [%date% %time%] AUTOLOG FAILED > %AUTOLOG_FAIL%
EXIT