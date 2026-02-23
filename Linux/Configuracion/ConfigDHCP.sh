#!/bin/bash
function configurar_dhcp() {
    clear
    echo "--- CONFIGURACION DE RED Y DHCP ---"
    ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"
    read -p "Nombre de la interfaz (ej. enp0s8): " INTERFAZ

    if ! ip link show "$INTERFAZ" > /dev/null 2>&1; then echo "Error: Interfaz no encontrada."; pausa; return; fi

    NOMBRE_AMBITO="Ambito_Default"
    RANGO_INI=$(pedir_dato_ip "IP Inicial")
    RANGO_FIN=$(pedir_dato_ip "IP Final")
    MASCARA=$(pedir_mascara "Mascara")
    GATEWAY=$(pedir_ip_opcional "Gateway")
    DNS1=$(pedir_ip_opcional "DNS Primario")
    LEASE_DEF=$(pedir_numero "Tiempo por defecto (s)" 600)
    LEASE_MAX=$(pedir_numero "Tiempo maximo (s)" 7200)

    SERVER_IP=$RANGO_INI
    CLIENT_START=$(siguiente_ip "$RANGO_INI")

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
    if [ -n "$GATEWAY" ]; then echo "    gateway $GATEWAY" >> /etc/network/interfaces; fi

    ip addr flush dev $INTERFAZ
    ip link set dev $INTERFAZ down
    ip link set dev $INTERFAZ up
    
    CIDR=24
    if [[ "$MASCARA" == "255.0.0.0" ]]; then CIDR=8; fi
    if [[ "$MASCARA" == "255.255.0.0" ]]; then CIDR=16; fi
    ip addr add $SERVER_IP/$CIDR dev $INTERFAZ 2>/dev/null

    rm -f /var/lib/dhcp/dhcpd.leases; touch /var/lib/dhcp/dhcpd.leases
    SUBNET=$(echo $SERVER_IP | cut -d'.' -f1-3).0

    cat <<EOF > /etc/dhcp/dhcpd.conf
default-lease-time $LEASE_DEF;
max-lease-time $LEASE_MAX;
authoritative;
subnet $SUBNET netmask $MASCARA {
    range $CLIENT_START $RANGO_FIN;
EOF
    if [ -n "$GATEWAY" ]; then echo "    option routers $GATEWAY;" >> /etc/dhcp/dhcpd.conf; fi
    if [ -n "$DNS1" ]; then echo "    option domain-name-servers $DNS1;" >> /etc/dhcp/dhcpd.conf; fi
    echo "}" >> /etc/dhcp/dhcpd.conf

    sed -i "s/INTERFACESv4=.*/INTERFACESv4=\"$INTERFAZ\"/" /etc/default/isc-dhcp-server
    systemctl restart isc-dhcp-server

    if systemctl is-active --quiet isc-dhcp-server; then echo "EXITO: DHCP Configurado."; else echo "FALLO AL INICIAR SERVICIO."; fi
    pausa
}