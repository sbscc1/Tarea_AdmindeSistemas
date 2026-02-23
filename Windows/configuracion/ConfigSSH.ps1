function Configurar-SSH {
    Clear-Host
    Write-Host "--- CONFIGURACION DE SERVICIO SSH ---"
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Write-Host "Iniciando servicio sshd..."
    Start-Service sshd -ErrorAction SilentlyContinue
    
    Write-Host "Comprobando reglas de Firewall"
    $ReglaFW = Get-NetFirewallRule -Name *OpenSSH-Server* -ErrorAction SilentlyContinue | Where-Object Direction -eq 'Inbound'
    
    if (-not $ReglaFW) {
        New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        Write-Host "Regla de firewall creada exitosamente."
    } else {
        Write-Host "La regla de firewall ya existe."
    }
    
    Write-Host "SSH configurado y listo para recibir conexiones remotas."
    Pausa
}