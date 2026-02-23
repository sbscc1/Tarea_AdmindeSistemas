#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Ejecutar como root (sudo)."
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CARPETAS=("Validaciones" "Instalaciones" "Configuracion" "Monitoreo" "Eliminacion")

for dir in "${CARPETAS[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        for file in "$SCRIPT_DIR/$dir"/*.sh; do
            if [ -f "$file" ]; then
                source "$file"
            fi
        done
    fi
done

function mostrar_menu_principal() {
    while true; do
        clear
        echo "=== PANEL DE ADMINISTRACION LINUX SERVER ==="
        echo "1. Informacion del Equipo"
        echo "2. Gestor DHCP"
        echo "3. Gestor DNS"
        echo "4. Gestor SSH"
        echo "5. Salir"
        read -p "Seleccione una opcion: " OPCION
        
        case $OPCION in
            1) ver_info_equipo ;;
            2) menu_dhcp ;;
            3) menu_dns ;;
            4) menu_ssh ;;
            5) exit 0 ;;
            *) echo "Opcion invalida."; sleep 1 ;;
        esac
    done
}

function menu_dhcp() {
    while true; do
        clear
        echo "--- GESTOR DHCP ---"
        echo "1. Instalar Rol"
        echo "2. Configurar Interfaz y Ambito"
        echo "3. Ver Estado del Servicio"
        echo "4. Ver Clientes Conectados"
        echo "5. Volver al Menu Principal"
        read -p "Opcion: " OP
        case $OP in
            1) instalar_dhcp ;;
            2) configurar_dhcp ;;
            3) ver_estado_dhcp ;;
            4) ver_leases_dhcp ;;
            5) return ;;
        esac
    done
}

function menu_dns() {
    while true; do
        clear
        echo "--- GESTOR DNS ---"
        echo "1. Configurar Zona (Directa + Inversa)"
        echo "2. Consultar Zonas"
        echo "3. Eliminar Zona"
        echo "4. Volver al Menu Principal"
        read -p "Opcion: " OP
        case $OP in
            1) configurar_dns ;;
            2) consultar_zonas_dns ;;
            3) eliminar_zona_dns ;;
            4) return ;;
        esac
    done
}

function menu_ssh() {
    while true; do
        clear
        echo "--- GESTOR SSH ---"
        echo "1. Instalar Servidor OpenSSH"
        echo "2. Configurar y Activar Servicio"
        echo "3. Monitor de Estado y Conexiones"
        echo "4. Volver al Menu Principal"
        read -p "Opcion: " OP
        case $OP in
            1) instalar_ssh ;;
            2) configurar_ssh ;;
            3) ver_estado_ssh ;;
            4) return ;;
        esac
    done
}

# 3. Iniciar Programa
mostrar_menu_principal