#!/bin/bash
function eliminar_zona_dns() {
    clear
    CONF_LOCAL="/etc/bind/named.conf.local"
    DIR_ZONAS="/var/cache/bind"
    echo "=== ELIMINAR ZONA ==="
    read -p "Nombre del dominio a borrar (ej. reprobados.com): " DOM_DEL
    
    if [ -z "$DOM_DEL" ]; then return; fi
    if ! grep -q "zone \"$DOM_DEL\"" "$CONF_LOCAL"; then echo "Dominio no encontrado."; pausa; return; fi

    read -p "Confirmar borrado? (s/n): " SURE
    if [[ "$SURE" == "s" ]]; then
        sed -i "/zone \"$DOM_DEL\"/,/};/d" "$CONF_LOCAL"
        rm -f "$DIR_ZONAS/db.$DOM_DEL"
        systemctl restart bind9
        echo "Eliminacion completada. (Archivos inversos deben limpiarse manualmente si es necesario)."
    fi
    pausa
}