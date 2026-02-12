#!/bin/bash

function ver_estado() {
    echo "--- ESTADO ---"
    systemctl status isc-dhcp-server --no-pager
    echo ""
    echo "--- IP SERVIDOR ---"
    ip -4 a | grep inet | grep -v "127.0.0.1"
}

function ver_leases() {
    echo "--- CLIENTES CONECTADOS ---"
    if [ -f /var/lib/dhcp/dhcpd.leases ]; then
        grep -E "lease|client-hostname" /var/lib/dhcp/dhcpd.leases | tail -n 20
    else
        echo "Sin registros aun."
    fi
}

function verificar_instalacion() {
    echo "--- VERIFICACION ---"
    if dpkg -l | grep -q isc-dhcp-server; then
        echo "ESTADO: INSTALADO"
        echo "VERSION:"
        dpkg -l | grep isc-dhcp-server | awk '{print $3}'
    else
        echo "ESTADO: NO INSTALADO"
    fi
}