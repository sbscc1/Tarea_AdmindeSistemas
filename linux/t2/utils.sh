#!/bin/bash

function ip_a_int() {
    local IFS=.
    read -r i1 i2 i3 i4 <<< "$1"
    if [[ ! "$i1" =~ ^[0-9]+$ ]]; then echo 0; return; fi
    echo $(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
}

function validar_logica_red() {
    local inicio=$1
    local fin=$2
    local mask=$3

    local i_inicio=$(ip_a_int "$inicio")
    local i_fin=$(ip_a_int "$fin")
    local i_mask=$(ip_a_int "$mask")

    # 1. Validar que Inicio sea MENOR que Fin
    if [ "$i_inicio" -ge "$i_fin" ]; then
        echo "ERROR LOGICO: La IP Inicial ($inicio) debe ser MENOR a la Final ($fin)." >&2
        return 1
    fi

    # 2. Validar que esten en el MISMO SEGMENTO
    local red_inicio=$(( i_inicio & i_mask ))
    local red_fin=$(( i_fin & i_mask ))

    if [ "$red_inicio" -ne "$red_fin" ]; then
        echo "ERROR LOGICO: Las IPs no pertenecen a la misma subred (Mascara: $mask)." >&2
        echo "Revise que los primeros octetos coincidan." >&2
        return 1
    fi

    return 0
}

# --- VALIDACIONES ---

function es_ip_prohibida() {
    local ip=$1
    local prohibidas=("0.0.0.0" "1.0.0.0" "127.0.0.0" "127.0.0.1" "255.255.255.255")
    for prohibida in "${prohibidas[@]}"; do
        if [[ "$ip" == "$prohibida" ]]; then return 0; fi
    done
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
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octetos <<< "$ip"
        if [[ ${octetos[0]} -le 255 && ${octetos[1]} -le 255 && ${octetos[2]} -le 255 && ${octetos[3]} -le 255 ]]; then return 0; fi
    fi
    return 1
}

# --- INTERACCION (AQUI ESTABA EL ERROR) ---

function pedir_dato_ip() {
    local mensaje=$1
    local valida=false
    local input=""
    while [ "$valida" = false ]; do
        read -p "$mensaje: " input
        if validar_ip_estricta "$input"; then
            valida=true
        else
            if es_ip_prohibida "$input"; then
                echo "ERROR: IP prohibida/reservada." >&2
            else
                echo "ERROR: Formato invalido." >&2
            fi
        fi
    done
    echo "$input"
}

function pedir_ip_opcional() {
    local mensaje=$1
    local valida=false
    local input=""
    while [ "$valida" = false ]; do
        read -p "$mensaje (Enter para omitir): " input
        if [ -z "$input" ]; then echo ""; return 0; fi
        if validar_ip_estricta "$input"; then
            valida=true
            echo "$input"
        else
            echo "ERROR: IP invalida." >&2
        fi
    done
}

function pedir_mascara() {
    local mensaje=$1
    local valida=false
    local input=""
    while [ "$valida" = false ]; do
        read -p "$mensaje: " input
        if validar_formato_mascara "$input"; then
            valida=true;
        else
            echo "ERROR: Mascara invalida." >&2
        fi
    done
    echo "$input"
}

function pedir_numero() {
    local mensaje=$1
    local default=$2
    local valida=false
    local input=""

    while [ "$valida" = false ]; do
        read -p "$mensaje [Default: $default]: " input
        if [ -z "$input" ]; then echo "$default"; return 0; fi

        if [[ "$input" =~ ^[0-9]+$ ]]; then
            if [ "$input" -gt 0 ]; then
                echo "$input"
                valida=true
            else
                echo "ERROR: El valor debe ser mayor a 0." >&2
            fi
        else
            echo "ERROR: Debe ingresar un numero entero valido." >&2
        fi
    done
}

function siguiente_ip() {
    local ip=$1
    IFS='.' read -r i1 i2 i3 i4 <<< "$ip"
    local next_i4=$((i4 + 1))
    echo "$i1.$i2.$i3.$next_i4"
}

function pausa() {
    echo ""
    read -p "Presione Enter para continuar..."
    echo ""
}