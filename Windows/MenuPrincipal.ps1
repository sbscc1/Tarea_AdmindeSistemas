$Principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecutar como ADMINISTRADOR."
    Start-Sleep 3
    Exit
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Carpetas = @("validaciones", "instalaciones", "configuracion", "monitoreo", "eliminacion")

foreach ($Carpeta in $Carpetas) {
    $RutaCarpeta = Join-Path -Path $ScriptPath -ChildPath $Carpeta
    if (Test-Path $RutaCarpeta) {
        $Archivos = Get-ChildItem -Path $RutaCarpeta -Filter *.ps1
        foreach ($Archivo in $Archivos) {
            . $Archivo.FullName
        }
    }
}

function Mostrar-MenuPrincipal {
    do {
        Clear-Host
        Write-Host "=== PANEL DE ADMINISTRACION WINDOWS SERVER ==="
        Write-Host "1. Informacion del Equipo"
        Write-Host "2. Gestor DHCP"
        Write-Host "3. Gestor DNS"
        Write-Host "4. Gestor SSH"
        Write-Host "5. Salir"
        $Opcion = Read-Host "Seleccione una opcion"
        
        switch ($Opcion) {
            "1" { Ver-InfoEquipo }
            "2" { Menu-DHCP }
            "3" { Menu-DNS }
            "4" { Menu-SSH }
            "5" { Exit }
        }
    } while ($true)
}

function Menu-DHCP {
    do {
        Clear-Host
        Write-Host "--- GESTOR DHCP ---"
        Write-Host "1. Instalar Rol + Firewall"
        Write-Host "2. Configurar Ambito"
        Write-Host "3. Ver Estado"
        Write-Host "4. Ver Clientes"
        Write-Host "5. Volver al Menu Principal"
        $Op = Read-Host "Opcion"
        switch ($Op) {
            "1" { Instalar-RolDHCP }
            "2" { Configurar-DHCP }
            "3" { Ver-EstadoDHCP }
            "4" { Ver-ClientesDHCP }
            "5" { return }
        }
    } while ($true)
}

function Menu-DNS {
    do {
        Clear-Host
        Write-Host "--- GESTOR DNS ---"
        Write-Host "1. Configurar Zona (Directa + Inversa)"
        Write-Host "2. Consultar Zonas"
        Write-Host "3. Eliminar Zona"
        Write-Host "4. Volver al Menu Principal"
        $Op = Read-Host "Opcion"
        switch ($Op) {
            "1" { Configurar-DNS }
            "2" { Consultar-DNS }
            "3" { Eliminar-DNS }
            "4" { return }
        }
    } while ($true)
}

function Menu-SSH {
    do {
        Clear-Host
        Write-Host "--- GESTOR SSH ---"
        Write-Host "1. Instalar Servidor OpenSSH"
        Write-Host "2. Configurar Servicio y Firewall"
        Write-Host "3. Monitor de Estado y Conexiones"
        Write-Host "4. Volver al Menu Principal"
        $Op = Read-Host "Opcion"
        switch ($Op) {
            "1" { Instalar-ServidorSSH }
            "2" { Configurar-SSH }
            "3" { Ver-EstadoSSH }
            "4" { return }
        }
    } while ($true)
}

Mostrar-MenuPrincipal