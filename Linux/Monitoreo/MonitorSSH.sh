#!/bin/bash
function ver_estado_ssh() {
    clear
    echo "--- ESTADO DEL SERVICIO SSH ---"
    systemctl status ssh --no-pager | head -n 10
    
    pausa
}