function Configurar-DHCP {
    Clear-Host
    Write-Host "--- 2. CONFIGURACION DE RED Y DHCP ---"
    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize | Out-Host

    $NombreInterfaz = Read-Host "Nombre EXACTO de la interfaz"
    if (-not (Get-NetAdapter -Name $NombreInterfaz -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Interfaz no encontrada."; Pausa; return
    }

    $NombreAmbito = Read-Host "Nombre del Ambito (Enter para Default)"
    if ([string]::IsNullOrWhiteSpace($NombreAmbito)) { $NombreAmbito = "Ambito_Default" }

    $ValidacionRed = $false
    while (-not $ValidacionRed) {
        $RangoIni = Pedir-Dato-IP "IP Inicial"
        $RangoFin = Pedir-Dato-IP "IP Final"
        $Mascara  = Pedir-Mascara "Mascara"
        if (Validar-Logica-Red $RangoIni $RangoFin $Mascara) { $ValidacionRed = $true }
    }

    $Gateway = Pedir-IP-Opcional "Gateway"
    $DNS     = Pedir-IP-Opcional "DNS Primario"
    $LeaseDef = Pedir-Numero "Tiempo Lease (Segundos)" 600

    $ServerIP = $RangoIni
    $ClientStart = Calcular-Siguiente-IP $RangoIni
    $Prefijo = 24
    if ($Mascara -eq "255.0.0.0") { $Prefijo = 8 }
    elseif ($Mascara -eq "255.255.0.0") { $Prefijo = 16 }

    Write-Host "Aplicando configuracion..."
    try {
        Remove-NetIPAddress -InterfaceAlias $NombreInterfaz -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $NombreInterfaz -Confirm:$false -ErrorAction SilentlyContinue

        if ($Gateway) { New-NetIPAddress -InterfaceAlias $NombreInterfaz -IPAddress $ServerIP -PrefixLength $Prefijo -DefaultGateway $Gateway -ErrorAction Stop | Out-Null }
        else { New-NetIPAddress -InterfaceAlias $NombreInterfaz -IPAddress $ServerIP -PrefixLength $Prefijo -ErrorAction Stop | Out-Null }
        
        if ($DNS) { Set-DnsClientServerAddress -InterfaceAlias $NombreInterfaz -ServerAddresses $DNS -ErrorAction SilentlyContinue }

        Start-Sleep -Seconds 5
        Restart-Service DhcpServer -Force -ErrorAction SilentlyContinue
        Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $NombreAmbito } | Remove-DhcpServerv4Scope -Force -ErrorAction SilentlyContinue

        $TimeSpan = New-TimeSpan -Seconds $LeaseDef
        Add-DhcpServerv4Scope -Name $NombreAmbito -StartRange $ClientStart -EndRange $RangoFin -SubnetMask $Mascara -State Active -LeaseDuration $TimeSpan -ErrorAction Stop
        
        $ScopeObj = Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $NombreAmbito }
        if ($Gateway) { Set-DhcpServerv4OptionValue -ScopeId $ScopeObj.ScopeId -OptionId 3 -Value $Gateway }
        if ($DNS) { Invoke-Expression "netsh dhcp server scope $($ScopeObj.ScopeId) set optionvalue 6 IPADDRESS $DNS" | Out-Null }

        Set-DhcpServerv4Binding -BindingState $true -InterfaceAlias $NombreInterfaz
        Restart-Service DhcpServer -Force

        Write-Host "EXITO: DHCP Configurado."
    } catch { Write-Host "ERROR CRITICO: $_" }
    Pausa
}