@REM Remove Cygwin

set CYGWIN_HOME=C:\cygwin
set CYGWIN_REMOVE_LOG=C:\cygwin\cygwin_rm.log
set CYGWIN_REMOVE_DONE=C:\cygwin\cygwin_rm.done

@ echo Remove cygwin with log in %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove the sshd service > %CYGWIN_REMOVE_LOG%
sc delete sshd >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing sshd service >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove cygwin shotcut >> %CYGWIN_REMOVE_LOG%
del "C:\Users\Public\Desktop\Cygwin Terminal.lnk" >>%CYGWIN_REMOVE_LOG% 2>&1
rd /s /q "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cygwin" >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing cygwin shotcut >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove cygwin user >> %CYGWIN_REMOVE_LOG%
net user sshd /delete >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing cygwin user >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove user idcuser >> %CYGWIN_REMOVE_LOG%
net user idcuser /delete >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing user idcuser >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove cygwin environment variables >> %CYGWIN_REMOVE_LOG%
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v CYGWIN /f >>%CYGWIN_REMOVE_LOG% 2>&1
set PathValue="%systemroot%\system32;%systemroot%;%systemroot%\system32\wbem;%systemroot%\system32\windowspowershell\v1.0\;c:\program files\ibm\gsk8\lib64;c:\program files (x86)\ibm\gsk8\lib;C:\IBM\SQLLIB\BIN;C:\IBM\SQLLIB\FUNCTION;C:\IBM\SQLLIB\SAMPLES\REPL"
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d %PathValue% /f >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing cygwin environment variables >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] Start to remove cygwin registry >> %CYGWIN_REMOVE_LOG%
REG DELETE "HKCU\Software\Cygwin" /f >>%CYGWIN_REMOVE_LOG% 2>&1
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Cygwin" /f >>%CYGWIN_REMOVE_LOG% 2>&1
echo [%date% %time%] End of removing cygwin registry >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] End of all the steps for removing cygwin >> %CYGWIN_REMOVE_LOG%

echo [%date% %time%] CYGWIN REMOVE DONE > %CYGWIN_REMOVE_DONE%

@REM Remove CYGWIN_HOME next by ssh
@REM /cygdrive/c/Windows/system32/shutdown.exe /t 600 /s
@REM netsh advfirewall firewall delete rule name="tcp" && rm -rf --no-preserve-root /cygdrive/c/cygwin/