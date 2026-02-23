function Configurar-DNS {
    Clear-Host
    Write-Host "=== CONFIGURACION DNS ==="
    
    if ((Get-WindowsFeature -Name DNS).Installed -eq $false) {
        Write-Host "Instalando Rol DNS..."
        Install-WindowsFeature DNS -IncludeManagementTools | Out-Null
    }

    $Dominio = Pedir-Dominio-Validado
    
    $IP_Actual = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.PrefixOrigin -eq "Manual"}).IPAddress
    if ($IP_Actual) {
        $Usar = Read-Host "IP Estatica detectada: $IP_Actual. Usar esta IP? (s/n)"
        if ($Usar -eq 's') { $IP_Srv = $IP_Actual } else { $IP_Srv = Read-Host "Ingrese IP Manual" }
    } else {
        $IP_Srv = Read-Host "Ingrese IP del Servidor"
    }

    $ZonaInversa = Calcular-Zona-Inversa $IP_Srv
    Write-Host "`nConfigurando:`n > Directa: $Dominio`n > Inversa: $ZonaInversa"

    try {
        if (-not (Get-DnsServerZone -Name $Dominio -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -Name $Dominio -ZoneFile "$Dominio.dns" -ErrorAction Stop
        }

        $RegA = Get-DnsServerResourceRecord -ZoneName $Dominio -RRType A -Name "@" -ErrorAction SilentlyContinue
        if ($RegA) { Remove-DnsServerResourceRecord -ZoneName $Dominio -RRType A -Name "@" -Force -ErrorAction SilentlyContinue }
        Add-DnsServerResourceRecordA -Name "@" -ZoneName $Dominio -IPv4Address $IP_Srv -ErrorAction Stop
        
        $RegCname = Get-DnsServerResourceRecord -ZoneName $Dominio -RRType CName -Name "www" -ErrorAction SilentlyContinue
        if (-not $RegCname) { Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "$Dominio" -ZoneName $Dominio }

        if (-not (Get-DnsServerZone -Name $ZonaInversa -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -Name $ZonaInversa -ZoneFile "$ZonaInversa.dns" -ErrorAction Stop
        }

        $UltimoOcteto = $IP_Srv.Split('.')[3]
        $PTR = Get-DnsServerResourceRecord -ZoneName $ZonaInversa -RRType Ptr -ErrorAction SilentlyContinue | Where-Object {$_.HostName -eq $UltimoOcteto}
        if (-not $PTR) { Add-DnsServerResourceRecordPtr -Name $UltimoOcteto -ZoneName $ZonaInversa -PtrDomainName "$Dominio" }

        $Nic = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceAlias $Nic.Name -ServerAddresses ("127.0.0.1")

        Restart-Service DNS -Force
        Write-Host "CONFIGURACION COMPLETADA."
    } catch { Write-Host "ERROR CRITICO: $_" }
    Pausa
}