#!/bin/bash
function instalar_dhcp() {
    clear
    echo "--- INSTALACION DHCP ---"
    if dpkg -l | grep -q isc-dhcp-server; then
        echo "Paquete isc-dhcp-server ya esta instalado."
    else
        echo "Instalando isc-dhcp-server..."
        apt-get update -qq > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server -qq > /dev/null 2>&1
        echo "Instalacion completada."
    fi
    pausa
}