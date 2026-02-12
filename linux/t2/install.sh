#!/bin/bash

function instalar_paquetes() {
    echo "--- INSTALACION ---"
    if dpkg -l | grep -q isc-dhcp-server; then
        echo "Paquete ya instalado."
    else
        apt-get update -qq
        apt-get install -y isc-dhcp-server
        echo "Instalado correctamente."
    fi
}