#!/bin/bash
clear
echo "________________________________________"
echo "   REPORTE DE ESTADO: $(hostname)"
echo " "
echo ">Ip actual:"
hostname -I
echo " "
echo "  Disco:"
df -h / | grep /
echo " "
