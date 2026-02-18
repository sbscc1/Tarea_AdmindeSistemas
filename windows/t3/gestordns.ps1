if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecutar como ADMINISTRADOR."
    Start-Sleep 3
    Exit
}

function Pedir-Dominio-Validado {
    do {
        $InputUser = Read-Host "Nombre del Dominio (ej. reprobados.com)"
        $DominioLimpio = $InputUser.Trim().ToLower()
        
        if ($DominioLimpio.StartsWith("www.")) {
            $DominioLimpio = $DominioLimpio.Substring(4)
            Write-Host "   Nota: Se elimino 'www.' para configurar la Zona Raiz."
        }

        if ($DominioLimpio -match "^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$") {
            return $DominioLimpio
        } else {
            Write-Host "ERROR: Formato invalido."
        }
    } while ($true)
}

function Calcular-Zona-Inversa {
    param($IP)
    try {
        $Octetos = $IP.Split('.')
        $NombreZona = "$($Octetos[2]).$($Octetos[1]).$($Octetos[0]).in-addr.arpa"
        return $NombreZona
    } catch { return $null }
}


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
        Write-Host "IP Estatica detectada: $IP_Actual"
        $Usar = Read-Host "Usar esta IP? (s/n)"
        if ($Usar -eq 's') { $IP_Srv = $IP_Actual } else { $IP_Srv = Read-Host "Ingrese IP Manual" }
    } else {
        $IP_Srv = Read-Host "Ingrese IP del Servidor (No se detecto estatica)"
    }

    $ZonaInversa = Calcular-Zona-Inversa $IP_Srv
    Write-Host "`nConfigurando:`n > Directa: $Dominio`n > Inversa: $ZonaInversa"

    try {
        if (-not (Get-DnsServerZone -Name $Dominio -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -Name $Dominio -ZoneFile "$Dominio.dns" -ErrorAction Stop
            Write-Host "Zona Directa creada."
        } else { Write-Host "AVISO: Zona Directa ya existe." }

        $RegA = Get-DnsServerResourceRecord -ZoneName $Dominio -RRType A -Name "@" -ErrorAction SilentlyContinue
        if ($RegA) {
            Remove-DnsServerResourceRecord -ZoneName $Dominio -RRType A -Name "@" -Force -ErrorAction SilentlyContinue
        }
        
        Add-DnsServerResourceRecordA -Name "@" -ZoneName $Dominio -IPv4Address $IP_Srv -ErrorAction Stop
        
        $RegCname = Get-DnsServerResourceRecord -ZoneName $Dominio -RRType CName -Name "www" -ErrorAction SilentlyContinue
        if (-not $RegCname) {
            Add-DnsServerResourceRecordCName -Name "www" -HostNameAlias "$Dominio" -ZoneName $Dominio
        }

        if (-not (Get-DnsServerZone -Name $ZonaInversa -ErrorAction SilentlyContinue)) {
            Add-DnsServerPrimaryZone -Name $ZonaInversa -ZoneFile "$ZonaInversa.dns" -ErrorAction Stop
            Write-Host "Zona Inversa creada."
        } else { Write-Host "AVISO: Zona Inversa ya existe." }

        $Octetos = $IP_Srv.Split('.')
        $UltimoOcteto = $Octetos[3]
        
        $PTR = Get-DnsServerResourceRecord -ZoneName $ZonaInversa -RRType Ptr -ErrorAction SilentlyContinue | Where-Object {$_.HostName -eq $UltimoOcteto}
        if (-not $PTR) {
            Add-DnsServerResourceRecordPtr -Name $UltimoOcteto -ZoneName $ZonaInversa -PtrDomainName "$Dominio"
            Write-Host "Registro PTR creado."
        }

        Write-Host "Ajustando DNS del adaptador..."
        $Nic = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceAlias $Nic.Name -ServerAddresses ("127.0.0.1")

        Restart-Service DNS -Force
        Write-Host "CONFIGURACION COMPLETADA."

    } catch {
        Write-Host "ERROR CRITICO: $_"
    }
    Read-Host "Enter para continuar..."
}


function Consultar-DNS {
    Clear-Host
    Write-Host "=== ZONAS CONFIGURADAS ==="
    Get-DnsServerZone | Select-Object ZoneName, ZoneType, IsAutoCreated | Format-Table -AutoSize | Out-Host
    
    $Dom = Read-Host "Ver registros de zona (Enter para omitir)"
    if ($Dom) {
        Get-DnsServerResourceRecord -ZoneName $Dom | Format-Table -AutoSize | Out-Host
    }
    Read-Host "Enter para continuar..."
}

function Eliminar-DNS {
    Clear-Host
    Write-Host "=== ELIMINAR ZONA ==="
    $Dom = Read-Host "Nombre del Dominio a borrar"
    
    if (Get-DnsServerZone -Name $Dom -ErrorAction SilentlyContinue) {
        $Conf = Read-Host "Seguro borrar $Dom y su inversa asociada? (s/n)"
        if ($Conf -eq 's') {
            Remove-DnsServerZone -Name $Dom -Force
            Write-Host "Zona Directa eliminada."
            
            $IP_Local = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress
            $Inversa = Calcular-Zona-Inversa $IP_Local
            if (Get-DnsServerZone -Name $Inversa -ErrorAction SilentlyContinue) {
                Remove-DnsServerZone -Name $Inversa -Force
                Write-Host "Zona Inversa ($Inversa) eliminada."
            }
        }
    } else {
        Write-Host "Zona no encontrada."
    }
    Read-Host "Enter para continuar..."
}

do {
    Clear-Host
    Write-Host "=== GESTOR DNS WINDOWS SERVER ==="
    Write-Host "1. Configurar Todo (Directa + Inversa)"
    Write-Host "2. Consultar Zonas"
    Write-Host "3. Eliminar Zona"
    Write-Host "4. Salir"
    $Op = Read-Host "Opcion"
    switch ($Op) {
        "1" { Configurar-DNS }
        "2" { Consultar-DNS }
        "3" { Eliminar-DNS }
        "4" { Exit }
    }
} while ($true)