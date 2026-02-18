#!/bin/bash

source ./utils.sh

CONF_LOCAL="/etc/bind/named.conf.local"
DIR_ZONAS="/var/cache/bind"

if [ "$EUID" -ne 0 ]; then echo "Ejecutar como root (sudo)."; exit 1; fi

function instalar_bind() {
    echo "--- INSTALACIÓN DE BIND9 ---"
    if dpkg -l | grep -q "bind9 "; then
        echo "BIND9 ya está instalado."
    else
        echo "Instalando bind9 bind9utils bind9-doc..."
        apt-get update -qq > /dev/null 2>&1
        DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils bind9-doc -qq > /dev/null 2>&1
        echo "Instalado correctamente."
    fi
}

function obtener_datos_inversa() {
    IFS='.' read -r i1 i2 i3 i4 <<< "$1"
    
    echo "$i3.$i2.$i1.in-addr.arpa db.$i1.$i2.$i3 $i4"
}


function configurar_nuevo_dns() {

    instalar_bind

    echo ""
    echo "=== CONFIGURACIÓN DE NUEVA ZONA DNS ==="
    
    DOMINIO=$(pedir_dominio)
    
    IP_ACTUAL=$(hostname -I | awk '{print $1}')
    echo "IP detectada: $IP_ACTUAL"
    read -p "¿Usar esta IP? (s/n): " CONFIRM
    if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
        IP_SRV=$IP_ACTUAL
    else
        IP_SRV=$(pedir_dato_ip "Ingrese la IP del Servidor")
    fi

    read -r ZONA_REV FILE_REV_NAME OCTETO_PTR <<< $(obtener_datos_inversa "$IP_SRV")
    
    FILE_DIRECTA="$DIR_ZONAS/db.$DOMINIO"
    FILE_INVERSA="$DIR_ZONAS/$FILE_REV_NAME"

    if grep -q "zone \"$DOMINIO\"" "$CONF_LOCAL"; then
        echo "El dominio $DOMINIO ya existe. Usa la opción 'Eliminar' primero."
        return
    fi

    echo "------------------------------------------------"
    echo " Configurando:"
    echo " Zona Directa: $DOMINIO"
    echo " Zona Inversa: $ZONA_REV"
    echo "------------------------------------------------"

    cat <<EOF >> "$CONF_LOCAL"

// ZONA: $DOMINIO
zone "$DOMINIO" {
    type master;
    file "$FILE_DIRECTA";
};

zone "$ZONA_REV" {
    type master;
    file "$FILE_INVERSA";
};
// FIN: $DOMINIO
EOF

    SERIAL=$(date +%Y%m%d01)
    cat <<EOF > "$FILE_DIRECTA"
\$TTL    604800
@       IN      SOA     ns1.$DOMINIO. admin.$DOMINIO. (
                              $SERIAL ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMINIO.
@       IN      A       $IP_SRV
ns1     IN      A       $IP_SRV
www     IN      CNAME   ns1
EOF

    cat <<EOF > "$FILE_INVERSA"
\$TTL    604800
@       IN      SOA     ns1.$DOMINIO. admin.$DOMINIO. (
                              $SERIAL ; Serial
                         604800     ; Refresh
                          86400     ; Retry
                        2419200     ; Expire
                         604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMINIO.
$OCTETO_PTR      IN      PTR     ns1.$DOMINIO.
$OCTETO_PTR      IN      PTR     www.$DOMINIO.
EOF
    
    chown bind:bind "$FILE_DIRECTA" "$FILE_INVERSA"

    if named-checkconf; then
        systemctl restart bind9
        echo "Zonas creadas y servicio reiniciado."
    else
        echo "Error de sintaxis en configuración BIND."
    fi
}


function consultar_zonas() {
    echo ""
    echo "=== ZONAS CONFIGURADAS ==="
    echo "--- En named.conf.local ---"
    grep "zone \"" "$CONF_LOCAL" | awk '{print $2}' | tr -d '"'
    
    echo ""
    echo "--- Archivos Físicos ---"
    ls -1 "$DIR_ZONAS" | grep "db."
    
    echo ""
    read -p "Presione Enter para continuar..."
}


function eliminar_zona() {
    echo ""
    echo "=== ELIMINAR ZONA ==="
    read -p "Nombre del dominio a borrar (ej. reprobados.com): " DOM_DEL
    
    if [ -z "$DOM_DEL" ]; then echo "Cancelado."; return; fi

    if ! grep -q "zone \"$DOM_DEL\"" "$CONF_LOCAL"; then
        echo "Dominio no encontrado."
        return
    fi

    echo "ADVERTENCIA: Se borrará la configuración de $DOM_DEL y sus archivos."
    read -p "¿Confirmar borrado? (s/n): " SURE
    if [[ "$SURE" != "s" ]]; then return; fi

    sed -i "/\/\/ ZONA: $DOM_DEL/,/\/\/ FIN: $DOM_DEL/d" "$CONF_LOCAL"
    
    rm -f "$DIR_ZONAS/db.$DOM_DEL"
    
    systemctl restart bind9
    echo "Eliminación completada."
}


while true; do
    clear
    echo "========================================"
    echo "   GESTOR DNS     "
    echo "========================================"
    echo "1. Configurar Zona"
    echo "2. Consultar Zonas"
    echo "3. Eliminar Zona"
    echo "4. Estado del Servicio"
    echo "5. Salir"
    echo "========================================"
    read -p "Opción: " OP

    case $OP in
        1) configurar_nuevo_dns; sleep 3 ;;
        2) consultar_zonas ;;
        3) eliminar_zona; sleep 3 ;;
        4) systemctl status bind9 --no-pager; read -p "Enter..." ;;
        5) exit 0 ;;
        *) echo "Opción inválida." ;;
    esac
done