@echo off

title stopServer

for /f "skip=3 tokens=4" %%i in ('sc query "IBMWAS85Service - Node1Server"') do set "zt=%%i" &goto :next   
:next  
if /i "%zt%"=="RUNNING" (  
	echo Stoping WASService for Node1Server, please wait ...
	net stop "IBMWAS85Service - Node1Server"
) else (
	echo Running WASService for Node1Server was not found.
)

for /f "skip=3 tokens=4" %%i in ('sc query "IBMWAS85Service - Node1Profile"') do set "zt=%%i" &goto :next   
:next  
if /i "%zt%"=="RUNNING" (  
	echo Stoping WASService for Node1Profile, please wait ...
	net stop "IBMWAS85Service - Node1Profile"
) else (
	echo Running WASService for Node1Profile was not found.
)

for /f "skip=3 tokens=4" %%i in ('sc query "IBMWAS85Service - DmgrProfile"') do set "zt=%%i" &goto :next   
:next  
if /i "%zt%"=="RUNNING" (  
	echo Stoping WASService for DmgrProfile, please wait ...
	net stop "IBMWAS85Service - DmgrProfile"
) else (
	echo Running WASService for DmgrProfile was not found.
)