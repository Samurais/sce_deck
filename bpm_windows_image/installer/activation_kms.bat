@echo off

cls
echo Activating Windws .. Please wait as this might take several minutes...
echo.
cscript //nologo "%windir%\system32\slmgr.vbs" /ato

echo Activation complete!