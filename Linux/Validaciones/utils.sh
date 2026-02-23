#!/bin/bash

function ip_a_int() {
    local IFS=.
    read -r i1 i2 i3 i4 <<< "$1"
    if [[ ! "$i1" =~ ^[0-9]+$ ]]; then echo 0; return; fi
    echo $(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
}

function validar_logica_red() {
    local i_inicio=$(ip_a_int "$1")
    local i_fin=$(ip_a_int "$2")
    local i_mask=$(ip_a_int "$3")
    if [ "$i_inicio" -ge "$i_fin" ]; then echo "ERROR: Inicio debe ser MENOR a Final." >&2; return 1; fi
    if [ $(( i_inicio & i_mask )) -ne $(( i_fin & i_mask )) ]; then echo "ERROR: Distinta subred." >&2; return 1; fi
    return 0
}

function es_ip_prohibida() {
    local ip=$1
    local prohibidas=("0.0.0.0" "1.0.0.0" "127.0.0.0" "127.0.0.1" "255.255.255.255")
    for p in "${prohibidas[@]}"; do if [[ "$ip" == "$p" ]]; then return 0; fi; done
    return 1
}

function validar_ip_estricta() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then return 1; fi
    IFS='.' read -r -a octetos <<< "$ip"
    if [[ ${octetos[0]} -gt 255 || ${octetos[1]} -gt 255 || ${octetos[2]} -gt 255 || ${octetos[3]} -gt 255 ]]; then return 1; fi
    if es_ip_prohibida "$ip"; then return 1; fi
    return 0
}

function validar_formato_mascara() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then return 0; fi
    return 1
}

function pedir_dato_ip() {
    local input=""
    while true; do
        read -p "$1: " input
        if validar_ip_estricta "$input"; then echo "$input"; return; else echo "ERROR: IP invalida." >&2; fi
    done
}

function pedir_ip_opcional() {
    local input=""
    while true; do
        read -p "$1 (Enter para omitir): " input
        if [ -z "$input" ]; then echo ""; return; fi
        if validar_ip_estricta "$input"; then echo "$input"; return; else echo "ERROR: IP invalida." >&2; fi
    done
}

function pedir_mascara() {
    local input=""
    while true; do
        read -p "$1: " input
        if validar_formato_mascara "$input"; then echo "$input"; return; else echo "ERROR: Mascara invalida." >&2; fi
    done
}

function pedir_numero() {
    local input=""
    while true; do
        read -p "$1 [Default: $2]: " input
        if [ -z "$input" ]; then echo "$2"; return; fi
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ]; then echo "$input"; return; else echo "ERROR: Invalido." >&2; fi
    done
}

function siguiente_ip() {
    IFS='.' read -r i1 i2 i3 i4 <<< "$1"
    echo "$i1.$i2.$i3.$((i4 + 1))"
}

function limpiar_dominio() {
    local limpio=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    limpio=${limpio#www.}
    if [[ ! "$limpio" =~ ^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,6}$ ]]; then echo "error"; return 1; fi
    echo "$limpio"
}

function pedir_dominio() {
    local input="" final=""
    while true; do
        read -p "Nombre del Dominio (ej. reprobados.com): " input
        final=$(limpiar_dominio "$input")
        if [[ "$final" == "error" ]]; then echo "ERROR: Formato invalido." >&2; else
            if [[ "$input" == *"www."* ]]; then echo "Nota: Se elimino el prefijo 'www.'." >&2; fi
            echo "$final"; return
        fi
    done
}

function obtener_datos_inversa() {
    IFS='.' read -r i1 i2 i3 i4 <<< "$1"
    echo "$i3.$i2.$i1.in-addr.arpa db.$i1.$i2.$i3 $i4"
}

function pausa() {
    echo ""
    read -p "Presione Enter para continuar..."
}