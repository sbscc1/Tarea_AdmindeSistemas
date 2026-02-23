function Eliminar-DNS {
    Clear-Host
    Write-Host "=== ELIMINAR ZONA ==="
    $Dom = Read-Host "Nombre del Dominio a borrar"
    
    if (Get-DnsServerZone -Name $Dom -ErrorAction SilentlyContinue) {
        $Conf = Read-Host "Seguro borrar $Dom y su inversa? (s/n)"
        if ($Conf -eq 's') {
            Remove-DnsServerZone -Name $Dom -Force
            Write-Host "Zona Directa eliminada."
            
            $IP_Local = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress
            $Inversa = Calcular-Zona-Inversa $IP_Local
            if (Get-DnsServerZone -Name $Inversa -ErrorAction SilentlyContinue) {
                Remove-DnsServerZone -Name $Inversa -Force
                Write-Host "Zona Inversa eliminada."
            }
        }
    } else { Write-Host "Zona no encontrada." }
    Pausa
}