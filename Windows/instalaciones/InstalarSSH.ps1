function Instalar-ServidorSSH {
    Clear-Host
    Write-Host "--- INSTALACION DE OPENSSH SERVER ---"
    
    $SSH_Pkg = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    
    if ($SSH_Pkg.State -ne 'Installed') {
        Write-Host "Instalando OpenSSH Server (Esto puede tardar unos minutos)..."
        Add-WindowsCapability -Online -Name $SSH_Pkg.Name | Out-Host
        Write-Host "Instalacion completada."
    } else {
        Write-Host "OpenSSH Server ya se encuentra instalado."
    }
    Pausa
}