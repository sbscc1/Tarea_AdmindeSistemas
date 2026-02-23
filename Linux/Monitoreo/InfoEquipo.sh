#!/bin/bash
function ver_info_equipo() {
    clear
    echo "________________________________________"
    echo "   REPORTE DE ESTADO: $(hostname)"
    echo "________________________________________"
    echo ""
    echo "> Ip actual:"
    hostname -I | awk '{print $1}'
    echo ""
    echo "> Disco Raiz (/):"
    df -h / | awk 'NR==2 {print "Total: " $2 " | Usado: " $3 " | Libre: " $4}'
    pausa
}