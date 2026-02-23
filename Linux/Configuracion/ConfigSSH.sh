#!/bin/bash
function configurar_ssh() {
    clear
    echo "--- CONFIGURACION DE SERVICIO SSH ---"
    
    echo "Activando el servicio ssh para inicio automatico"
    systemctl enable ssh > /dev/null 2>&1
    
    echo "Iniciando servicio ssh"
    systemctl start ssh
    
    echo "SSH configurado."
    pausa
}