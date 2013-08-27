@echo off
@REM Necessary configuration on Windows after BPM install

set POSTINSTALL_DONE=C:\cygwin\post_install.done

echo [%date% %time%] Modify firewall to allow java.exe
netsh advfirewall firewall add rule name="Java(TM) Platform SE binary" dir=in program=C:\IBM\BPM\v8.5\java\bin\java.exe remoteip=Any protocol=TCP profile=public action=allow
netsh advfirewall firewall add rule name="Java(TM) Platform SE binary" dir=in program=C:\IBM\BPM\v8.5\java\bin\java.exe remoteip=Any protocol=UDP profile=public action=allow

copy C:\installer\Script\buildID C:\

echo [%date% %time%] Deleting the directory C:\ntcheck 
if exist C:\ntcheck\ (
   rd /s /q C:\ntcheck
)
echo [%date% %time%] Deleting the directory C:\installer 
echo [%date% %time%] POST INSTALL DONE > %POSTINSTALL_DONE%
rd /s /q C:\installer