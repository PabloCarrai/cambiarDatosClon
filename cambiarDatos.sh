#!/bin/bash

#	Muestra ayuda
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Uso: sudo bash cambiarDatos.sh"
    echo "Uso: sudo ./cambiarDatos.sh"
    echo "  -h, --help    Muestra esta ayuda"
    exit 0
fi

cambiar_nombre(){
   MI_EQUIPO=$(hostname)
   # 1. Solicitar el ingreso de la cadena
   read -p "Bauticemos a este equipo, nuevo nombre? : " NOMBRE_EQUIPO 
   # 2. Verificar si la variable está vacía
   if [ -z "$NOMBRE_EQUIPO" ]; then
      echo "Error: No ingresaste nada."
   else
      sed -i "s/${MI_EQUIPO}/${NOMBRE_EQUIPO}/g" /etc/hosts 
      hostnamectl set-hostname "${NOMBRE_EQUIPO}" 
   fi
   echo "Nombre del equipo cambiado $NOMBRE_EQUIPO"
}

reiniciar_id(){
   truncate -s 0 /etc/machine-id
   rm -f /var/lib/dbus/machine-id
   ln -sf /etc/machine-id /var/lib/dbus/machine-id
   systemd-machine-id-setup
} > /dev/null 2>&1

#	Chequeo que tenga permisos de sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse con privilegios sudo." 
   exit 1
else
   echo "1) Tienes permisos para continuar"
   cambiar_nombre
   echo "2) Regenerando id..."
   reiniciar_id
fi
