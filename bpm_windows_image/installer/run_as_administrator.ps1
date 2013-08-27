
$plain_password = $args[0]
$script_file = $args[1]
$parameter = ""
if ($args.Count -eq 3) {
  $parameter = $args[2]
}

$password = ConvertTo-SecureString -AsPlainText -Force $plain_password
$pro = [System.Diagnostics.Process]::Start($script_file, $parameter, "Administrator", $password,  "localhost")
$pro.WaitForExit()