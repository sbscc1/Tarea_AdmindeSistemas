#!/bin/bash

source ./utils.sh
source ./install.sh
source ./config.sh
source ./monitor.sh

if [ "$EUID" -ne 0 ]; then
  echo "Ejecutar como root."
  exit
fi

while true; do
    clear
    echo "=============================="
    echo "   GESTOR DHCP (LINUX)   "
    echo "=============================="
    echo "1. Instalar dependencias"
    echo "2. Configurar (IP Server + DHCP)"
    echo "3. Consultar estado"
    echo "4. Ver clientes (Leases)"
    echo "5. Verificar instalacion"
    echo "6. Salir"
    echo "=============================="
    read -p "Opcion: " op

    case $op in
        1) instalar_paquetes; pausa ;;
        2) configurar_sistema; pausa ;;
        3) ver_estado; pausa ;;
        4) ver_leases; pausa ;;
        5) verificar_instalacion; pausa ;;
        6) exit 0 ;;
        *) echo "Invalido."; sleep 1 ;;
    esac
done