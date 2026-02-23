#!/bin/bash
function instalar_ssh() {
    clear
    echo "--- INSTALACION OPENSSH SERVER ---"
    if dpkg -l | grep -q "openssh-server"; then
        echo "OpenSSH Server ya esta instalado."
    else
        echo "Instalando openssh-server..."
        apt-get update -qq > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server -qq > /dev/null 2>&1
        echo "Instalacion completada."
    fi
    pausa
}