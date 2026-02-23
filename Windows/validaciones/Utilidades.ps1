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
    if ($i_Inicio -ge $i_Fin) { Write-Host "ERROR: Inicio debe ser MENOR a Final."; return $false }
    if (($i_Inicio -band $i_Mask) -ne ($i_Fin -band $i_Mask)) { Write-Host "ERROR: Distinta subred."; return $false }
    return $true
}

function Pedir-Dato-IP {
    param($Mensaje)
    do {
        $InputIP = Read-Host $Mensaje
        if (Validar-IP-Estricta $InputIP) { return $InputIP }
        else { Write-Host "ERROR: IP invalida." }
    } while ($true)
}

function Pedir-IP-Opcional {
    param($Mensaje)
    do {
        $InputIP = Read-Host "$Mensaje (Enter omitir)"
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
        $Input = Read-Host "$Mensaje [$Default]"
        if ([string]::IsNullOrWhiteSpace($Input)) { return [int]$Default }
        if ($Input -match "^[0-9]+$" -and [int]$Input -gt 0) { return [int]$Input }
        else { Write-Host "ERROR: Solo numeros mayores a 0." }
    } while ($true)
}

function Calcular-Siguiente-IP {
    param([string]$Ip)
    $Bytes = ([System.Net.IPAddress]::Parse($Ip)).GetAddressBytes()
    $Bytes[3] = $Bytes[3] + 1
    return (([System.Net.IPAddress]($Bytes)).IPAddressToString)
}

function Pedir-Dominio-Validado {
    do {
        $InputUser = Read-Host "Nombre del Dominio (ej. reprobados.com)"
        $DominioLimpio = $InputUser.Trim().ToLower()
        if ($DominioLimpio.StartsWith("www.")) {
            $DominioLimpio = $DominioLimpio.Substring(4)
            Write-Host "   Nota: Se elimino 'www.' para Zona Raiz."
        }
        if ($DominioLimpio -match "^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}$") { return $DominioLimpio } 
        else { Write-Host "ERROR: Formato invalido." }
    } while ($true)
}

function Calcular-Zona-Inversa {
    param($IP)
    try {
        $Octetos = $IP.Split('.')
        return "$($Octetos[2]).$($Octetos[1]).$($Octetos[0]).in-addr.arpa"
    } catch { return $null }
}

function Pausa {
    Write-Host ""
    Read-Host "Presione Enter para continuar..."
}