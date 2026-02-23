function Consultar-DNS {
    Clear-Host
    Write-Host "=== ZONAS CONFIGURADAS ==="
    Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsAutoCreated | Format-Table -AutoSize | Out-Host
    
    $Dom = Read-Host "Ver registros de zona (Enter para omitir)"
    if ($Dom) { Get-DnsServerResourceRecord -ZoneName $Dom | Format-Table -AutoSize | Out-Host }
    Pausa
}