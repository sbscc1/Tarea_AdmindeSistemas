#!/bin/bash
function configurar_dns() {
    instalar_dns
    clear
    echo "=== CONFIGURACION DE NUEVA ZONA DNS ==="
    CONF_LOCAL="/etc/bind/named.conf.local"
    DIR_ZONAS="/var/cache/bind"
    
    DOMINIO=$(pedir_dominio)
    IP_ACTUAL=$(hostname -I | awk '{print $1}')
    read -p "Usar IP detectada ($IP_ACTUAL)? (s/n): " CONFIRM
    if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then IP_SRV=$IP_ACTUAL; else IP_SRV=$(pedir_dato_ip "Ingrese la IP del Servidor"); fi

    read -r ZONA_REV FILE_REV_NAME OCTETO_PTR <<< $(obtener_datos_inversa "$IP_SRV")
    FILE_DIRECTA="$DIR_ZONAS/db.$DOMINIO"
    FILE_INVERSA="$DIR_ZONAS/$FILE_REV_NAME"

    if grep -q "zone \"$DOMINIO\"" "$CONF_LOCAL"; then echo "El dominio $DOMINIO ya existe."; pausa; return; fi

    echo "Configurando Directa e Inversa..."
    cat <<EOF >> "$CONF_LOCAL"
zone "$DOMINIO" { type master; file "$FILE_DIRECTA"; };
zone "$ZONA_REV" { type master; file "$FILE_INVERSA"; };
EOF

    SERIAL=$(date +%Y%m%d01)
    cat <<EOF > "$FILE_DIRECTA"
\$TTL    604800
@       IN      SOA     ns1.$DOMINIO. admin.$DOMINIO. ($SERIAL 604800 86400 2419200 604800)
@       IN      NS      ns1.$DOMINIO.
@       IN      A       $IP_SRV
ns1     IN      A       $IP_SRV
www     IN      CNAME   ns1
EOF

    cat <<EOF > "$FILE_INVERSA"
\$TTL    604800
@       IN      SOA     ns1.$DOMINIO. admin.$DOMINIO. ($SERIAL 604800 86400 2419200 604800)
@       IN      NS      ns1.$DOMINIO.
$OCTETO_PTR      IN      PTR     ns1.$DOMINIO.
$OCTETO_PTR      IN      PTR     www.$DOMINIO.
EOF
    
    chown bind:bind "$FILE_DIRECTA" "$FILE_INVERSA"
    if named-checkconf; then systemctl restart bind9; echo "Configuracion exitosa."; else echo "Error de sintaxis."; fi
    pausa
}