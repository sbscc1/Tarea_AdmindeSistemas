function Ver-EstadoSSH {
    Clear-Host
    Write-Host "--- ESTADO DEL SERVICIO SSH ---"
    
    $Servicio = Get-Service sshd -ErrorAction SilentlyContinue
    if ($Servicio) { 
        $Servicio | Select-Object Name, Status, StartType | Format-List | Out-Host 
        
        Write-Host "--- CONEXIONES SSH ACTIVAS ---"
        $Conexiones = Get-NetTCPConnection -LocalPort 22 -ErrorAction SilentlyContinue | Where-Object State -eq 'Established'
        
        if ($Conexiones) {
            $Conexiones | Select-Object LocalAddress, LocalPort, RemoteAddress, State | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host "No hay clientes conectados por SSH en este momento."
        }
        
    } else { 
        Write-Host "SERVICIO SSH NO ENCONTRADO" 
    }
    Pausa
}