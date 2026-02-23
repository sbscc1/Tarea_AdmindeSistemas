#!/bin/bash
function ver_estado_dhcp() {
    clear
    echo "--- ESTADO DHCP ---"
    systemctl status isc-dhcp-server --no-pager
    pausa
}

function ver_leases_dhcp() {
    clear
    echo "--- CLIENTES CONECTADOS ---"
    if [ -f /var/lib/dhcp/dhcpd.leases ]; then
        grep -E "lease|client-hostname" /var/lib/dhcp/dhcpd.leases | tail -n 20
    else
        echo "Sin registros aun."
    fi
    pausa
}