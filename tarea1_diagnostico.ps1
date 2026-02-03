Clear-Host
Write-Host "__________________________________________" 
Write-Host "   Nombre de equipo: $env:COMPUTERNAME   " 
Write-Host "__________________________________________" 
Write-Host " "
Write-Host " Ip: "
Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress | Out-Host
Write-Host " "
Write-Host " Disco: " 
Get-PSDrive C | Select-Object @{N="Libre(GB)";E={[math]::round($_.Free/1GB,2)}}, @{N="Total(GB)";E={[math]::round($_.Used/1GB + $_.Free/1GB,2)}} | Out-Host
Write-Host " "