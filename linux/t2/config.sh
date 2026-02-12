#!/bin/bash

source ./utils.sh

function configurar_sistema() {
    echo "--- CONFIGURACION DE RED Y DHCP ---"

    echo "Interfaces detectadas:"
    ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
    echo ""
    read -p "Nombre de la interfaz (ej. enp0s8): " INTERFAZ

    if ! ip link show "$INTERFAZ" > /dev/null 2>&1; then
        echo "Error: Interfaz no encontrada."
        return 1
    fi

    echo ""
    read -p "Nombre del Ambito DHCP (Enter para default): " NOMBRE_AMBITO
    if [ -z "$NOMBRE_AMBITO" ]; then NOMBRE_AMBITO="Ambito_Default"; fi

    echo ""
    echo "--- DATOS DE RED ---"
    VALIDO=false

    while [ "$VALIDO" = false ]; do
        RANGO_INI=$(pedir_dato_ip "IP Inicial (ej. 192.168.100.50)")
        RANGO_FIN=$(pedir_dato_ip "IP Final   (ej. 192.168.100.150)")
        MASCARA=$(pedir_mascara "Mascara de Subred (ej. 255.255.255.0)")

        echo "Verificando logica de red..."
        if validar_logica_red "$RANGO_INI" "$RANGO_FIN" "$MASCARA"; then
            echo "Todo bien."
            VALIDO=true
        else
            echo "--- Error. ingrese de nuevo el dato ---"
            echo ""
        fi
    done

    GATEWAY=$(pedir_ip_opcional "Gateway")
    DNS1=$(pedir_ip_opcional "DNS Primario")
    echo ""
    echo "--- TIEMPOS DE CONCESION (LEASE) ---"
    LEASE_DEF=$(pedir_numero "Tiempo por defecto (segundos)" 600)
    LEASE_MAX=$(pedir_numero "Tiempo maximo (segundos)" 7200)

    SERVER_IP=$RANGO_INI
    CLIENT_START=$(siguiente_ip "$RANGO_INI")

    echo ""
    echo "Aplicando configuracion..."

    cp /etc/network/interfaces /etc/network/interfaces.bak 2>/dev/null

    cat <<EOF > /etc/network/interfaces
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

allow-hotplug $INTERFAZ
iface $INTERFAZ inet static
    address $SERVER_IP
    netmask $MASCARA
EOF

    if [ -n "$GATEWAY" ]; then
        echo "    gateway $GATEWAY" >> /etc/network/interfaces
    fi

    echo "Reiniciando interfaz $INTERFAZ..."
    ip addr flush dev $INTERFAZ
    ip link set dev $INTERFAZ down
    ip link set dev $INTERFAZ up

    CIDR=24
    if [[ "$MASCARA" == "255.0.0.0" ]]; then CIDR=8; fi
    if [[ "$MASCARA" == "255.255.0.0" ]]; then CIDR=16; fi
    ip addr add $SERVER_IP/$CIDR dev $INTERFAZ

    rm -f /var/lib/dhcp/dhcpd.leases
    touch /var/lib/dhcp/dhcpd.leases

    SUBNET=$(echo $SERVER_IP | cut -d'.' -f1-3).0

    cat <<EOF > /etc/dhcp/dhcpd.conf
default-lease-time $LEASE_DEF;
max-lease-time $LEASE_MAX;
authoritative;

subnet $SUBNET netmask $MASCARA {
    # Ambito: $NOMBRE_AMBITO
    range $CLIENT_START $RANGO_FIN;
EOF

    if [ -n "$GATEWAY" ]; then
        echo "    option routers $GATEWAY;" >> /etc/dhcp/dhcpd.conf
    fi

    if [ -n "$DNS1" ]; then
        echo "    option domain-name-servers $DNS1;" >> /etc/dhcp/dhcpd.conf
    fi

    echo "}" >> /etc/dhcp/dhcpd.conf

    sed -i "s/INTERFACESv4=.*/INTERFACESv4=\"$INTERFAZ\"/" /etc/default/isc-dhcp-server

    echo "Reiniciando servicio DHCP..."
    systemctl restart isc-dhcp-server

    if systemctl is-active --quiet isc-dhcp-server; then
        echo "EXITO: DHCP Configurado."
        echo "IP Server: $SERVER_IP"
        echo "Lease Time: $LEASE_DEF seg (Max: $LEASE_MAX seg)"
    else
        echo "FALLO AL INICIAR SERVICIO."
        systemctl status isc-dhcp-server --no-pager
    fi
}