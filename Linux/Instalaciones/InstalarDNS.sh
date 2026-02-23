#!/bin/bash
function instalar_dns() {
    clear
    echo "--- INSTALACION BIND9 ---"
    if dpkg -l | grep -q "bind9 "; then
        echo "BIND9 ya esta instalado."
    else
        echo "Instalando bind9 bind9utils bind9-doc..."
        apt-get update -qq > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils bind9-doc -qq > /dev/null 2>&1
        echo "Instalacion completada."
    fi
}