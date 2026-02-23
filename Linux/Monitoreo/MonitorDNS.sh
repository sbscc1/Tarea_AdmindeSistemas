#!/bin/bash
function consultar_zonas_dns() {
    clear
    CONF_LOCAL="/etc/bind/named.conf.local"
    DIR_ZONAS="/var/cache/bind"
    echo "=== ZONAS CONFIGURADAS ==="
    echo "--- En named.conf.local ---"
    grep "zone \"" "$CONF_LOCAL" | awk '{print $2}' | tr -d '"' 2>/dev/null
    echo ""
    echo "--- Archivos Fisicos ---"
    ls -1 "$DIR_ZONAS" | grep "db." 2>/dev/null
    pausa
}