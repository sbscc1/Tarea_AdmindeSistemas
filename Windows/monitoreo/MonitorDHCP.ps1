function Ver-EstadoDHCP {
    Clear-Host
    Write-Host "--- ESTADO DEL SERVICIO DHCP ---"
    $Servicio = Get-Service DhcpServer -ErrorAction SilentlyContinue
    if ($Servicio) { $Servicio | Select-Object Name, Status, StartType | Format-List | Out-Host } 
    else { Write-Host "SERVICIO NO ENCONTRADO" }

    Write-Host "--- IP ACTUAL ---"
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize | Out-Host

    Write-Host "--- BINDINGS ---"
    Get-DhcpServerv4Binding | Select-Object InterfaceAlias, IPAddress, BindingState | Format-Table -AutoSize | Out-Host
    Pausa
}

function Ver-ClientesDHCP {
    Clear-Host
    Write-Host "--- CLIENTES CONECTADOS ---"
    try {
        $Leases = Get-DhcpServerv4Scope | Get-DhcpServerv4Lease
        if ($Leases) { $Leases | Select-Object IPAddress, ClientId, HostName, LeaseExpires | Format-Table -AutoSize | Out-Host } 
        else { Write-Host "Sin clientes aun." }
    } catch { Write-Host "No se pudieron leer los leases." }
    Pausa
}