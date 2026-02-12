
$Principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecutar como ADMINISTRADOR."
    Start-Sleep 3
    Exit
}


function Convertir-IP-A-Int {
    param([string]$Ip)
    try {
        $Bytes = [System.Net.IPAddress]::Parse($Ip).GetAddressBytes()
        if ([System.BitConverter]::IsLittleEndian) { [Array]::Reverse($Bytes) }
        return [System.BitConverter]::ToUInt32($Bytes, 0)
    } catch { return 0 }
}

function Es-IP-Prohibida {
    param([string]$Ip)
    $Blacklist = @("0.0.0.0", "1.0.0.0", "127.0.0.0", "127.0.0.1", "255.255.255.255")
    if ($Blacklist -contains $Ip) { return $true }
    if ($Ip.StartsWith("127.")) { return $true }
    return $false
}

function Validar-IP-Estricta {
    param([string]$Ip)
    if ($Ip -notmatch "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") { return $false }
    try {
        $Obj = [System.Net.IPAddress]::Parse($Ip)
        $Bytes = $Obj.GetAddressBytes()
        if ($Bytes[0] -eq 255) { return $false }
    } catch { return $false }
    if (Es-IP-Prohibida $Ip) { return $false }
    return $true
}

function Validar-Logica-Red {
    param($Inicio, $Fin, $Mascara)
    $i_Inicio = Convertir-IP-A-Int $Inicio
    $i_Fin    = Convertir-IP-A-Int $Fin
    $i_Mask   = Convertir-IP-A-Int $Mascara

    if ($i_Inicio -ge $i_Fin) {
        Write-Host "ERROR LOGICO: La IP Inicial debe ser MENOR a la Final."
        return $false
    }
    $Red_Inicio = $i_Inicio -band $i_Mask
    $Red_Fin    = $i_Fin -band $i_Mask

    if ($Red_Inicio -ne $Red_Fin) {
        Write-Host "ERROR LOGICO: Las IPs no pertenecen a la misma subred."
        return $false
    }
    return $true
}

function Pedir-Dato-IP {
    param($Mensaje)
    do {
        $InputIP = Read-Host $Mensaje
        if (Validar-IP-Estricta $InputIP) { return $InputIP }
        elseif (Es-IP-Prohibida $InputIP) { Write-Host "ERROR: IP prohibida." }
        else { Write-Host "ERROR: Formato invalido." }
    } while ($true)
}

function Pedir-IP-Opcional {
    param($Mensaje)
    do {
        $InputIP = Read-Host "$Mensaje (Enter para omitir)"
        if ([string]::IsNullOrWhiteSpace($InputIP)) { return $null }
        if (Validar-IP-Estricta $InputIP) { return $InputIP }
        else { Write-Host "ERROR: IP invalida." }
    } while ($true)
}

function Pedir-Mascara {
    param($Mensaje)
    do {
        $InputIP = Read-Host $Mensaje
        if ($InputIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") { return $InputIP }
        else { Write-Host "ERROR: Mascara invalida." }
    } while ($true)
}

function Pedir-Numero {
    param($Mensaje, $Default)
    do {
        $Input = Read-Host "$Mensaje [Default: $Default]"
        if ([string]::IsNullOrWhiteSpace($Input)) { return [int]$Default }
        if ($Input -match "^[0-9]+$") {
            if ([int]$Input -gt 0) { return [int]$Input }
            else { Write-Host "ERROR: Debe ser mayor a 0." }
        } else { Write-Host "ERROR: Solo numeros enteros." }
    } while ($true)
}

function Calcular-Siguiente-IP {
    param([string]$Ip)
    $Bytes = ([System.Net.IPAddress]::Parse($Ip)).GetAddressBytes()
    $Bytes[3] = $Bytes[3] + 1
    return (([System.Net.IPAddress]($Bytes)).IPAddressToString)
}

function Pausa {
    Write-Host ""
    Read-Host "Presione Enter para continuar..."
    Write-Host ""
}


function Instalar-Rol {
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

function Configurar-Todo {
    Clear-Host
    Write-Host "--- 2. CONFIGURACION DE RED Y DHCP ---"

    Get-NetAdapter | Select-Object Name, InterfaceDescription, Status | Format-Table -AutoSize | Out-Host

    $NombreInterfaz = Read-Host "Nombre EXACTO de la interfaz (ej. Ethernet 2)"
    if (-not (Get-NetAdapter -Name $NombreInterfaz -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Interfaz no encontrada."
        Pausa
        return
    }

    Write-Host "`n--- DATOS DE RED ---"
    $NombreAmbito = Read-Host "Nombre del Ambito (Enter para Default)"
    if ([string]::IsNullOrWhiteSpace($NombreAmbito)) { $NombreAmbito = "Ambito_Default" }

    $ValidacionRed = $false
    while (-not $ValidacionRed) {
        $RangoIni = Pedir-Dato-IP "IP Inicial (ej. 192.168.100.50)"
        $RangoFin = Pedir-Dato-IP "IP Final   (ej. 192.168.100.150)"
        $Mascara  = Pedir-Mascara "Mascara    (ej. 255.255.255.0)"
        Write-Host "Verificando logica..."
        if (Validar-Logica-Red $RangoIni $RangoFin $Mascara) {
            Write-Host "Rango valido."
            $ValidacionRed = $true
        } else { Write-Host "INTENTE DE NUEVO" }
    }

    $Gateway = Pedir-IP-Opcional "Gateway"
    $DNS     = Pedir-IP-Opcional "DNS Primario"
    Write-Host "`n--- TIEMPOS DE LEASE ---"
    $LeaseDef = Pedir-Numero "Tiempo Lease (Segundos)" 600

    $ServerIP = $RangoIni
    $ClientStart = Calcular-Siguiente-IP $RangoIni
    $Prefijo = 24
    if ($Mascara -eq "255.0.0.0") { $Prefijo = 8 }
    elseif ($Mascara -eq "255.255.0.0") { $Prefijo = 16 }

    Write-Host "`nAplicando configuracion..."
    try {
        Remove-NetIPAddress -InterfaceAlias $NombreInterfaz -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $NombreInterfaz -Confirm:$false -ErrorAction SilentlyContinue

        if ($Gateway) {
            New-NetIPAddress -InterfaceAlias $NombreInterfaz -IPAddress $ServerIP -PrefixLength $Prefijo -DefaultGateway $Gateway -ErrorAction Stop | Out-Null
        } else {
            New-NetIPAddress -InterfaceAlias $NombreInterfaz -IPAddress $ServerIP -PrefixLength $Prefijo -ErrorAction Stop | Out-Null
        }
        if ($DNS) { Set-DnsClientServerAddress -InterfaceAlias $NombreInterfaz -ServerAddresses $DNS -ErrorAction SilentlyContinue }

        Write-Host "Red configurada. Esperando 5 seg..."
        Start-Sleep -Seconds 5

        Restart-Service DhcpServer -Force -ErrorAction SilentlyContinue
        Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $NombreAmbito } | Remove-DhcpServerv4Scope -Force -ErrorAction SilentlyContinue

        $TimeSpan = New-TimeSpan -Seconds $LeaseDef
        Add-DhcpServerv4Scope -Name $NombreAmbito -StartRange $ClientStart -EndRange $RangoFin -SubnetMask $Mascara -State Active -LeaseDuration $TimeSpan -ErrorAction Stop

        $ScopeObj = Get-DhcpServerv4Scope | Where-Object { $_.Name -eq $NombreAmbito }
        $ScopeID = $ScopeObj.ScopeId

        if ($Gateway) { Set-DhcpServerv4OptionValue -ScopeId $ScopeID -OptionId 3 -Value $Gateway }
        if ($DNS) {
            $ComandoDNS = "netsh dhcp server scope $ScopeID set optionvalue 6 IPADDRESS $DNS"
            Invoke-Expression $ComandoDNS | Out-Null
        }

        Set-DhcpServerv4Binding -BindingState $true -InterfaceAlias $NombreInterfaz
        Restart-Service DhcpServer -Force

        Write-Host "EXITO: DHCP Configurado."
        Write-Host "   Server IP: $ServerIP"
        Write-Host "   Rango DHCP: $ClientStart - $RangoFin"
        Write-Host "   Lease Time: $LeaseDef seg"
    } catch { Write-Host "ERROR CRITICO: $_" }
    Pausa
}

function Ver-Estado {
    Clear-Host
    Write-Host "--- ESTADO DEL SERVICIO ---"
    $Servicio = Get-Service DhcpServer -ErrorAction SilentlyContinue
    if ($Servicio) {
        $Servicio | Select-Object Name, Status, StartType | Format-List | Out-Host
    } else {
        Write-Host "SERVICIO NO ENCONTRADO (Â¿Instalaste la Opcion 1?)" -ForegroundColor Red
    }

    Write-Host "--- IP ACTUAL ---"
    Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize | Out-Host

    Write-Host "--- BINDINGS (DONDE ESCUCHA) ---"
    Get-DhcpServerv4Binding | Select-Object InterfaceAlias, IPAddress, BindingState | Format-Table -AutoSize | Out-Host
    Pausa
}

function Ver-Clientes {
    Clear-Host
    Write-Host "--- CLIENTES CONECTADOS ---"
    try {
        $Leases = Get-DhcpServerv4Scope | Get-DhcpServerv4Lease
        if ($Leases) {
            $Leases | Select-Object IPAddress, ClientId, HostName, LeaseExpires | Format-Table -AutoSize | Out-Host
        } else {
            Write-Host "Sin clientes aun."
        }
    } catch { Write-Host "No se pudieron leer los leases (O no hay ambitos creados)." }
    Pausa
}

do {
    Clear-Host
    Write-Host "=== GESTOR DHCP WIN SERVER ==="
    Write-Host "1. Instalar Rol + Firewall"
    Write-Host "2. Configurar Todo"
    Write-Host "3. Ver Estado"
    Write-Host "4. Ver Clientes"
    Write-Host "5. Salir"
    $Op = Read-Host "Opcion"
    switch ($Op) {
        "1" { Instalar-Rol }
        "2" { Configurar-Todo }
        "3" { Ver-Estado }
        "4" { Ver-Clientes }
        "5" { Exit }
        default { Write-Host "Opcion invalida."; Start-Sleep 1 }
    }

} while ($true)
