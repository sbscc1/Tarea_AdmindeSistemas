function Instalar-RolDHCP {
    Clear-Host
    Write-Host "--- 1. INSTALACION Y FIREWALL ---"
    if ((Get-WindowsFeature -Name DHCP).Installed -eq $false) {
        Write-Host "Instalando DHCP..."
        Install-WindowsFeature -Name DHCP -IncludeManagementTools | Out-Host
    } else { Write-Host "Rol DHCP ya instalado." }

    Write-Host "Configurando Firewall..."
    try {
        New-NetFirewallRule -DisplayName "DHCP-In" -Direction Inbound -LocalPort 67,68 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue | Out-Null
        New-NetFirewallRule -DisplayName "DHCP-Out" -Direction Outbound -LocalPort 67,68 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Firewall configurado."
    } catch { Write-Host "Nota: Firewall ya estaba configurado." }
    Pausa
}