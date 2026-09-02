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

cambiar_llaves_ssh(){
   rm -f /etc/ssh/ssh_host_*_key*
   if command -v dpkg-reconfigure &> /dev/null; then
     dpkg-reconfigure openssh-server
   else
     sudo ssh-keygen -A
   fi
   sudo systemctl restart ssh
} > /dev/null 2>&1 

salir(){
   # Preguntar al usuario si desea apagar la VM
   read -p "¿Deseas apagar la máquina virtual ahora? (s/n): " respuesta
   case $respuesta in
      [sS]|[sS][iI])
         echo "Apagando el equipo..."
         shutdown -h now
         ;;
   esac
}

borrando_historial(){
   # 1. Borrar físicamente los archivos de historial existentes de todos los usuarios y root
   find /home /root -type f \( -name ".*_history" -o -name ".*_hist" -o -name ".*info" \) -exec rm -f {} +

   # 2. Asegurar que existan los archivos limpios y vacíos para evitar errores posteriores
   for user_home in $(awk -F: '$3 >= 1000 || $1 == "root" {print $6}' /etc/passwd); do
      if [ -d "$user_home" ]; then
         touch "$user_home/.bash_history"
         chown $(stat -c '%u:%g' "$user_home") "$user_home/.bash_history"
         chmod 600 "$user_home/.bash_history"
      fi
   done

   # 3. Limpiar la memoria RAM de la sesión actual y sobreescribir el archivo con vacíos (-cw)
   history -c
   history -w

   # 4. Proceder al apagado normal
   salir
}



#	Chequeo que tenga permisos de sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse con privilegios sudo." 
   exit 1
else
   echo "1) Tienes permisos para continuar"
   cambiar_nombre
   echo "2) Regenerando id..."
   reiniciar_id
   echo "3) Regenerando llaves ssh....."
   cambiar_llaves_ssh
   echo "4) Terminando el trabajo"
   borrando_historial
fi
