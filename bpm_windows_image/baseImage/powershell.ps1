if ((Test-Path "E:\") -eq $false) {
  "select disk 1", "online disk" | diskpart  
  "select disk 1", "attributes disk clear readonly" | diskpart
}

C:\cygwin\bin\mkgroup.exe -l > C:\cygwin\etc\group
C:\cygwin\bin\mkpasswd.exe -l > C:\cygwin\etc\passwd
